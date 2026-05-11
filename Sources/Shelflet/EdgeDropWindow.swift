import AppKit
import ShelfletCore

final class EdgeDropWindow: NSPanel {
    init(
        frame: NSRect,
        screen: NSScreen,
        edge: ShelfEdge,
        intakeCoordinator: DragIntakeCoordinator,
        shelfPanelController: ShelfPanelController,
        settingsProvider: @escaping () -> AppSettings
    ) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .canJoinAllApplications,
            .ignoresCycle
        ]

        self.contentView = EdgeDropView(
            screen: screen,
            edge: edge,
            intakeCoordinator: intakeCoordinator,
            shelfPanelController: shelfPanelController,
            settingsProvider: settingsProvider
        )
    }
}

final class EdgeDropView: NSView {
    private let owningScreen: NSScreen
    private let edge: ShelfEdge
    private let intakeCoordinator: DragIntakeCoordinator
    private let shelfPanelController: ShelfPanelController
    private let settingsProvider: () -> AppSettings
    private var revealWorkItem: DispatchWorkItem?

    init(
        screen: NSScreen,
        edge: ShelfEdge,
        intakeCoordinator: DragIntakeCoordinator,
        shelfPanelController: ShelfPanelController,
        settingsProvider: @escaping () -> AppSettings
    ) {
        self.owningScreen = screen
        self.edge = edge
        self.intakeCoordinator = intakeCoordinator
        self.shelfPanelController = shelfPanelController
        self.settingsProvider = settingsProvider
        super.init(frame: .zero)

        var draggedTypes: [NSPasteboard.PasteboardType] = [.fileURL]
        draggedTypes.append(contentsOf: NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType(rawValue: $0) })
        registerForDraggedTypes(draggedTypes)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let operation = intakeCoordinator.draggingEntered(sender)
        if !operation.isEmpty {
            scheduleReveal()
        }
        return operation
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        intakeCoordinator.draggingUpdated(sender)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        intakeCoordinator.prepareForDragOperation(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let didImport = intakeCoordinator.performDragOperation(sender)
        if didImport {
            shelfPanelController.show(on: owningScreen, edge: edge)
        }
        return didImport
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        revealWorkItem?.cancel()
        revealWorkItem = nil
        intakeCoordinator.draggingExited(sender)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        revealWorkItem?.cancel()
        revealWorkItem = nil
    }

    private func scheduleReveal() {
        revealWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.shelfPanelController.show(on: self.owningScreen, edge: self.edge)
        }
        revealWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + settingsProvider().revealDelay, execute: workItem)
    }
}
