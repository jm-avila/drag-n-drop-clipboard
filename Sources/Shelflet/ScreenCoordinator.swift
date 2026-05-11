import AppKit
import Foundation
import OSLog
import ShelfletCore

@MainActor
final class ScreenCoordinator {
    private let intakeCoordinator: DragIntakeCoordinator
    private let shelfPanelController: ShelfPanelController
    private let settingsProvider: () -> AppSettings
    private let logger = Logger(subsystem: "Shelflet", category: "ScreenCoordinator")

    private var edgeWindows: [EdgeDropWindow] = []
    private var observer: NSObjectProtocol?

    init(
        intakeCoordinator: DragIntakeCoordinator,
        shelfPanelController: ShelfPanelController,
        settingsProvider: @escaping () -> AppSettings
    ) {
        self.intakeCoordinator = intakeCoordinator
        self.shelfPanelController = shelfPanelController
        self.settingsProvider = settingsProvider
    }

    func start() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuild()
            }
        }

        rebuild()
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        closeEdgeWindows()
    }

    func rebuild() {
        closeEdgeWindows()

        let settings = settingsProvider()
        for screen in NSScreen.screens {
            let screenFrame = ScreenFrame(
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea,
                auxiliaryTopRightArea: screen.auxiliaryTopRightArea
            )

            for edge in settings.enabledEdges {
                for frame in ShelfGeometry.hotZoneFrames(screen: screenFrame, edge: edge, thickness: settings.hotZoneThickness) {
                    let window = EdgeDropWindow(
                        frame: frame,
                        screen: screen,
                        edge: edge,
                        intakeCoordinator: intakeCoordinator,
                        shelfPanelController: shelfPanelController,
                        settingsProvider: settingsProvider
                    )
                    window.orderFrontRegardless()
                    edgeWindows.append(window)
                    logger.info("Created edge window edge=\(edge.rawValue, privacy: .public) frame=\(String(describing: frame), privacy: .public)")
                }
            }
        }
    }

    private func closeEdgeWindows() {
        for window in edgeWindows {
            window.close()
        }
        edgeWindows.removeAll()
    }
}
