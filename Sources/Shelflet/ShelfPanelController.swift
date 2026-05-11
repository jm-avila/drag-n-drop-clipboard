import AppKit
import OSLog
import ShelfletCore

@MainActor
final class ShelfPanelController: NSObject {
    private let model: ShelfModel
    private let bookmarkService: BookmarkService
    private let cacheManager: CacheManager
    private let settingsProvider: () -> AppSettings
    private let thumbnailProvider = ThumbnailProvider()
    private let logger = Logger(subsystem: "Shelflet", category: "ShelfPanel")

    private let panel: NSPanel
    private let collectionView: ShelfCollectionView
    private var items: [ShelfItem] = []
    private var activeDragResources: [UUID: SecurityScopedURL] = [:]

    init(
        model: ShelfModel,
        bookmarkService: BookmarkService,
        cacheManager: CacheManager,
        settingsProvider: @escaping () -> AppSettings
    ) {
        self.model = model
        self.bookmarkService = bookmarkService
        self.cacheManager = cacheManager
        self.settingsProvider = settingsProvider

        self.panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.collectionView = ShelfCollectionView(frame: .zero)
        super.init()

        configurePanel()
        configureCollectionView()

        model.onChange = { [weak self] items in
            Task { @MainActor in
                self?.items = items
                self?.collectionView.reloadData()
            }
        }
    }

    func show(on screen: NSScreen? = NSScreen.screens.first, edge: ShelfEdge? = nil) {
        let targetScreen = screen ?? NSScreen.screens.first
        guard let targetScreen else {
            return
        }

        let effectiveEdge = edge ?? settingsProvider().enabledEdges.first ?? .right
        let screenFrame = ScreenFrame(
            frame: targetScreen.frame,
            visibleFrame: targetScreen.visibleFrame,
            auxiliaryTopLeftArea: targetScreen.auxiliaryTopLeftArea,
            auxiliaryTopRightArea: targetScreen.auxiliaryTopRightArea
        )
        let frame = ShelfGeometry.shelfFrame(
            screen: screenFrame,
            edge: effectiveEdge,
            preferredSize: CGSize(width: 420, height: 280),
            margin: 16
        )
        panel.setFrame(frame, display: true, animate: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func clearShelf() {
        let removed = model.clear()
        removeCachedFiles(for: removed)
    }

    private func configurePanel() {
        panel.title = "Shelflet"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isFloatingPanel = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 14
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = collectionView

        visualEffectView.addSubview(scrollView)
        panel.contentView = visualEffectView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -12)
        ])
    }

    private func configureCollectionView() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 92, height: 112)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColors = [.clear]
        collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)
        collectionView.setDraggingSourceOperationMask(.copy, forLocal: true)
        collectionView.register(ShelfCollectionItem.self, forItemWithIdentifier: ShelfCollectionItem.identifier)
        collectionView.deleteHandler = { [weak self] in
            self?.removeSelectedItems()
        }
    }

    private func removeSelectedItems() {
        let ids = Set(collectionView.selectionIndexPaths.compactMap { indexPath -> UUID? in
            guard indexPath.item < items.count else {
                return nil
            }
            return items[indexPath.item].id
        })

        let removed = model.remove(ids: ids)
        removeCachedFiles(for: removed)
    }

    private func removeCachedFiles(for removedItems: [ShelfItem]) {
        for item in removedItems {
            guard case let .cached(relativePath) = item.storage else {
                continue
            }

            do {
                try cacheManager.removeCachedItem(relativePath: relativePath)
            } catch {
                logger.error("Failed to remove cached file \(relativePath, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }

    private func resolvedURL(for item: ShelfItem) -> URL? {
        switch item.storage {
        case let .cached(relativePath):
            return try? cacheManager.url(forRelativePath: relativePath)
        case let .bookmark(bookmarkData):
            do {
                let resource = try bookmarkService.resolve(bookmarkData)
                defer { resource.stopAccessing() }

                if resource.isStale, let refreshedData = try? bookmarkService.bookmarkData(for: resource.url) {
                    model.updateBookmark(id: item.id, bookmarkData: refreshedData)
                }

                return resource.url
            } catch {
                model.updateAvailability(id: item.id, availability: .unresolved)
                logger.error("Failed to resolve bookmark for \(item.displayName, privacy: .public): \(String(describing: error), privacy: .public)")
                return nil
            }
        }
    }

    private func resolvedURLForDrag(for item: ShelfItem) -> URL? {
        switch item.storage {
        case let .cached(relativePath):
            return try? cacheManager.url(forRelativePath: relativePath)
        case let .bookmark(bookmarkData):
            do {
                activeDragResources[item.id]?.stopAccessing()

                let resource = try bookmarkService.resolve(bookmarkData)
                activeDragResources[item.id] = resource

                if resource.isStale, let refreshedData = try? bookmarkService.bookmarkData(for: resource.url) {
                    model.updateBookmark(id: item.id, bookmarkData: refreshedData)
                }

                return resource.url
            } catch {
                model.updateAvailability(id: item.id, availability: .unresolved)
                logger.error("Failed to resolve drag bookmark for \(item.displayName, privacy: .public): \(String(describing: error), privacy: .public)")
                return nil
            }
        }
    }

    private func clearActiveDragResources() {
        for resource in activeDragResources.values {
            resource.stopAccessing()
        }
        activeDragResources.removeAll()
    }
}

extension ShelfPanelController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ShelfCollectionItem.identifier, for: indexPath)
        guard let shelfItem = item as? ShelfCollectionItem else {
            return item
        }

        let modelItem = items[indexPath.item]
        shelfItem.configure(
            with: modelItem,
            fileURL: resolvedURL(for: modelItem),
            thumbnailProvider: thumbnailProvider
        )
        return shelfItem
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        pasteboardWriterForItemAt indexPath: IndexPath
    ) -> NSPasteboardWriting? {
        guard indexPath.item < items.count, let url = resolvedURLForDrag(for: items[indexPath.item]) else {
            return nil
        }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.absoluteString, forType: .fileURL)
        return pasteboardItem
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        canDragItemsAt indexPaths: Set<IndexPath>,
        with event: NSEvent
    ) -> Bool {
        indexPaths.contains { indexPath in
            guard indexPath.item < items.count else {
                return false
            }
            return resolvedURLForDrag(for: items[indexPath.item]) != nil
        }
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        draggingSession session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        dragOperation operation: NSDragOperation
    ) {
        defer { clearActiveDragResources() }

        let outcome: DragOutOutcome
        if operation.isEmpty {
            outcome = .cancelled
        } else if operation.contains(.copy) || operation.contains(.move) || operation.contains(.link) {
            outcome = .droppedAndAccepted
        } else {
            outcome = .droppedButFailedOrIgnored
        }

        let removalPolicy: ShelfRemovalAfterDragPolicy = settingsProvider().removeItemsAfterAcceptedDragOut
            ? .removeWhenDroppedAndAccepted
            : .keep

        guard DragOutPolicy.shouldRemoveItem(outcome: outcome, policy: removalPolicy) else {
            return
        }

        let draggedIDs = Set(collectionView.selectionIndexPaths.compactMap { indexPath -> UUID? in
            guard indexPath.item < items.count else {
                return nil
            }
            return items[indexPath.item].id
        })
        let removed = model.remove(ids: draggedIDs)
        removeCachedFiles(for: removed)
    }
}

final class ShelfCollectionView: NSCollectionView {
    var deleteHandler: (() -> Void)?

    override func shouldDelayWindowOrdering(for event: NSEvent) -> Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            deleteHandler?()
            return
        }

        super.keyDown(with: event)
    }
}

final class ShelfCollectionItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ShelfCollectionItem")

    private let itemImageView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")
    private var representedID: UUID?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 10

        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.imageScaling = .scaleProportionallyUpOrDown
        itemImageView.symbolConfiguration = .init(pointSize: 36, weight: .regular)

        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.alignment = .center
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.font = .systemFont(ofSize: 11)

        view.addSubview(itemImageView)
        view.addSubview(titleField)

        imageView = itemImageView
        textField = titleField

        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            itemImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 52),
            itemImageView.heightAnchor.constraint(equalToConstant: 52),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            titleField.topAnchor.constraint(equalTo: itemImageView.bottomAnchor, constant: 8),
            titleField.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4)
        ])
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.selectedControlColor.withAlphaComponent(0.25).cgColor
                : NSColor.clear.cgColor
        }
    }

    func configure(with item: ShelfItem, fileURL: URL?, thumbnailProvider: ThumbnailProvider) {
        representedID = item.id
        titleField.stringValue = item.displayName
        itemImageView.image = NSImage(named: item.availability == .available ? NSImage.multipleDocumentsName : NSImage.cautionName)

        let id = item.id
        thumbnailProvider.loadThumbnail(for: fileURL, size: CGSize(width: 52, height: 52)) { [weak self] image in
            guard self?.representedID == id else {
                return
            }
            self?.itemImageView.image = image
        }
    }
}
