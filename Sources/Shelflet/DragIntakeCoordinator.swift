import AppKit
import Foundation
import OSLog
import ShelfletCore

private extension DragOperationMask {
    init(nsDragOperation: NSDragOperation) {
        var mask: DragOperationMask = []
        if nsDragOperation.contains(.copy) { mask.insert(.copy) }
        if nsDragOperation.contains(.move) { mask.insert(.move) }
        if nsDragOperation.contains(.link) { mask.insert(.link) }
        self = mask
    }

    var nsDragOperation: NSDragOperation {
        var operation: NSDragOperation = []
        if contains(.copy) { operation.insert(.copy) }
        if contains(.move) { operation.insert(.move) }
        if contains(.link) { operation.insert(.link) }
        return operation
    }
}

struct DragClassification {
    var sequenceNumber: Int
    var fileURLs: [URL]
    var filePromises: [NSFilePromiseReceiver]
    var sourceApplication: String?

    var summary: DragPayloadSummary {
        DragPayloadSummary(
            fileURLCount: fileURLs.count,
            filePromiseCount: filePromises.count,
            unsupportedCount: fileURLs.isEmpty && filePromises.isEmpty ? 1 : 0
        )
    }
}

@MainActor
final class DragIntakeCoordinator {
    private let model: ShelfModel
    private let cacheManager: CacheManager
    private let itemFactory: FileItemFactory
    private let promiseQueue: OperationQueue
    private let logger = Logger(subsystem: "Shelflet", category: "DragIntake")

    private var classificationsBySequence: [Int: DragClassification] = [:]

    init(model: ShelfModel, cacheManager: CacheManager, itemFactory: FileItemFactory) {
        self.model = model
        self.cacheManager = cacheManager
        self.itemFactory = itemFactory
        self.promiseQueue = OperationQueue()
        self.promiseQueue.name = "Shelflet.FilePromises"
        self.promiseQueue.qualityOfService = .userInitiated
    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let classification = classify(sender)
        let sourceMask = DragOperationMask(nsDragOperation: sender.draggingSourceOperationMask)
        let accepted = DragIntakePolicy.acceptedOperation(source: sourceMask, payload: classification.summary)

        logger.info(
            "Drag entered seq=\(classification.sequenceNumber, privacy: .public) urls=\(classification.fileURLs.count, privacy: .public) promises=\(classification.filePromises.count, privacy: .public) accepted=\(accepted.rawValue, privacy: .public)"
        )

        return accepted.nsDragOperation
    }

    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let classification = classificationsBySequence[sender.draggingSequenceNumber] else {
            return draggingEntered(sender)
        }

        let sourceMask = DragOperationMask(nsDragOperation: sender.draggingSourceOperationMask)
        return DragIntakePolicy
            .acceptedOperation(source: sourceMask, payload: classification.summary)
            .nsDragOperation
    }

    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        classification(for: sender).summary.isSupported
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let classification = classification(for: sender)
        guard classification.summary.isSupported else {
            logger.info("Rejected unsupported drag seq=\(classification.sequenceNumber, privacy: .public)")
            return false
        }

        importFileURLs(classification.fileURLs, sourceApplication: classification.sourceApplication)
        materializePromises(classification.filePromises, sourceApplication: classification.sourceApplication)
        classificationsBySequence.removeValue(forKey: classification.sequenceNumber)
        return true
    }

    func draggingExited(_ sender: NSDraggingInfo?) {
        guard let sender else {
            return
        }

        classificationsBySequence.removeValue(forKey: sender.draggingSequenceNumber)
    }

    private func classification(for sender: NSDraggingInfo) -> DragClassification {
        classificationsBySequence[sender.draggingSequenceNumber] ?? classify(sender)
    }

    private func classify(_ sender: NSDraggingInfo) -> DragClassification {
        if let cached = classificationsBySequence[sender.draggingSequenceNumber] {
            return cached
        }

        let pasteboard = sender.draggingPasteboard
        let fileURLs = readFileURLs(from: pasteboard)
        let promises = readFilePromises(from: pasteboard)
        let classification = DragClassification(
            sequenceNumber: sender.draggingSequenceNumber,
            fileURLs: fileURLs,
            filePromises: promises,
            sourceApplication: sender.draggingSource.map { String(describing: type(of: $0)) }
        )
        classificationsBySequence[sender.draggingSequenceNumber] = classification
        return classification
    }

    private func readFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]

        guard pasteboard.canReadObject(forClasses: [NSURL.self], options: options) else {
            return []
        }

        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? []
        return objects.compactMap { object in
            if let url = object as? URL {
                return url
            }
            return (object as? NSURL)?.absoluteURL
        }
    }

    private func readFilePromises(from pasteboard: NSPasteboard) -> [NSFilePromiseReceiver] {
        guard pasteboard.canReadObject(forClasses: [NSFilePromiseReceiver.self], options: nil) else {
            return []
        }

        return pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] ?? []
    }

    private func importFileURLs(_ urls: [URL], sourceApplication: String?) {
        let importedItems = urls.compactMap { url -> ShelfItem? in
            do {
                return try itemFactory.makeReferencedItem(from: url, sourceApplication: sourceApplication)
            } catch {
                logger.error("Failed to import file URL \(url.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
                return nil
            }
        }

        model.add(importedItems)
    }

    private func materializePromises(_ promises: [NSFilePromiseReceiver], sourceApplication: String?) {
        guard !promises.isEmpty else {
            return
        }

        let destinationDirectory: URL
        do {
            destinationDirectory = try cacheManager.makePromiseBatchDirectory()
        } catch {
            logger.error("Failed to create promise cache directory: \(String(describing: error), privacy: .public)")
            return
        }

        for promise in promises {
            let promiseType = promise.fileTypes.first
            promise.receivePromisedFiles(atDestination: destinationDirectory, options: [:], operationQueue: promiseQueue) { [weak self] fileURL, error in
                guard let self else {
                    return
                }

                if let error {
                    self.logger.error("Promise materialization failed: \(String(describing: error), privacy: .public)")
                    return
                }

                do {
                    let item = try self.itemFactory.makeCachedItem(
                        from: fileURL,
                        sourceApplication: sourceApplication,
                        promiseTypeIdentifier: promiseType
                    )
                    DispatchQueue.main.async {
                        self.model.add([item])
                    }
                } catch {
                    self.logger.error("Failed to import materialized promise \(fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
                }
            }
        }
    }
}
