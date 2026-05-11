import Foundation

public struct DragOperationMask: OptionSet, Equatable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let copy = DragOperationMask(rawValue: 1 << 0)
    public static let move = DragOperationMask(rawValue: 1 << 1)
    public static let link = DragOperationMask(rawValue: 1 << 2)
}

public enum DragPayloadKind: Equatable, Sendable {
    case fileURLs
    case filePromises
    case plainText
    case mixedSupported
    case unsupported
}

public struct DragPayloadSummary: Equatable, Sendable {
    public var fileURLCount: Int
    public var filePromiseCount: Int
    public var textSnippetCount: Int
    public var unsupportedCount: Int

    public init(
        fileURLCount: Int = 0,
        filePromiseCount: Int = 0,
        textSnippetCount: Int = 0,
        unsupportedCount: Int = 0
    ) {
        self.fileURLCount = fileURLCount
        self.filePromiseCount = filePromiseCount
        self.textSnippetCount = textSnippetCount
        self.unsupportedCount = unsupportedCount
    }

    public var kind: DragPayloadKind {
        let hasURLs = fileURLCount > 0
        let hasPromises = filePromiseCount > 0
        let hasText = textSnippetCount > 0
        let supportedKinds = [hasURLs, hasPromises, hasText].filter { $0 }.count

        if supportedKinds > 1 {
            return .mixedSupported
        }

        if hasURLs {
            return .fileURLs
        }

        if hasPromises {
            return .filePromises
        }

        if hasText {
            return .plainText
        }

        return .unsupported
    }

    public var isSupported: Bool {
        fileURLCount + filePromiseCount + textSnippetCount > 0
    }
}

public enum DragIntakePolicy {
    public static func acceptedOperation(
        source: DragOperationMask,
        payload: DragPayloadSummary
    ) -> DragOperationMask {
        guard payload.isSupported else {
            return []
        }

        if source.contains(.copy) {
            return .copy
        }

        if source.contains(.move) {
            return .move
        }

        if source.contains(.link) {
            return .link
        }

        return []
    }
}

public enum DragOutOutcome: Equatable, Sendable {
    case droppedAndAccepted
    case cancelled
    case droppedButFailedOrIgnored
}

public enum ShelfRemovalAfterDragPolicy: Equatable, Sendable {
    case keep
    case removeWhenDroppedAndAccepted
}

public enum DragOutPolicy {
    public static func shouldRemoveItem(
        outcome: DragOutOutcome,
        policy: ShelfRemovalAfterDragPolicy
    ) -> Bool {
        outcome == .droppedAndAccepted && policy == .removeWhenDroppedAndAccepted
    }
}
