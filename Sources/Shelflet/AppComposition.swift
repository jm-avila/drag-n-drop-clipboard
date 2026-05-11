import AppKit
import Foundation
import OSLog
import ShelfletCore

@MainActor
final class AppComposition {
    private let logger = Logger(subsystem: "Shelflet", category: "App")

    private let settingsViewModel: SettingsViewModel
    private let model: ShelfModel
    private let cacheManager: CacheManager
    private let shelfPanelController: ShelfPanelController
    private let screenCoordinator: ScreenCoordinator
    private let statusItemController: StatusItemController
    private let settingsWindowController: SettingsWindowController

    init() {
        let settingsStore = SettingsStore(fileURL: ApplicationDirectories.settingsStoreURL)
        let loadedSettings = (try? settingsStore.load()) ?? AppSettings()
        let settingsViewModel = SettingsViewModel(settings: loadedSettings, store: settingsStore)
        self.settingsViewModel = settingsViewModel

        let bookmarkService = BookmarkService()
        let cacheManager = CacheManager(rootURL: ApplicationDirectories.cacheRootURL)
        self.cacheManager = cacheManager

        let shelfStore = ShelfStore(fileURL: ApplicationDirectories.shelfStoreURL)
        let model = ShelfModel(store: shelfStore)
        self.model = model

        let itemFactory = FileItemFactory(bookmarkService: bookmarkService, cacheManager: cacheManager)
        let shelfPanelController = ShelfPanelController(
            model: model,
            bookmarkService: bookmarkService,
            cacheManager: cacheManager,
            settingsProvider: { settingsViewModel.settings }
        )
        self.shelfPanelController = shelfPanelController

        let intakeCoordinator = DragIntakeCoordinator(
            model: model,
            cacheManager: cacheManager,
            itemFactory: itemFactory
        )

        let screenCoordinator = ScreenCoordinator(
            intakeCoordinator: intakeCoordinator,
            shelfPanelController: shelfPanelController,
            settingsProvider: { settingsViewModel.settings }
        )
        self.screenCoordinator = screenCoordinator

        let settingsWindowController = SettingsWindowController(viewModel: settingsViewModel)
        self.settingsWindowController = settingsWindowController

        self.statusItemController = StatusItemController(
            showShelf: { shelfPanelController.show() },
            hideShelf: { shelfPanelController.hide() },
            showSettings: { settingsWindowController.show() },
            clearShelf: { shelfPanelController.clearShelf() }
        )

        settingsViewModel.onSettingsChanged = { settings in
            NSApp.setActivationPolicy(settings.showDockIcon ? .regular : .accessory)
            screenCoordinator.rebuild()
        }
        settingsViewModel.onClearShelf = {
            shelfPanelController.clearShelf()
        }
    }

    func start() {
        NSApp.setActivationPolicy(settingsViewModel.settings.showDockIcon ? .regular : .accessory)
        do {
            try cacheManager.ensureRootExists()
        } catch {
            logger.error("Failed to create cache root: \(String(describing: error), privacy: .public)")
        }

        model.load()
        cleanupOrphanedPromiseDirectories()
        statusItemController.start()
        screenCoordinator.start()
        settingsViewModel.refreshLoginItemStatus()
    }

    func stop() {
        screenCoordinator.stop()
    }

    private func cleanupOrphanedPromiseDirectories() {
        let validRelativePaths = Set(model.items.compactMap(\.storage.cachedRelativePath))
        do {
            try cacheManager.cleanupTemporaryPromiseDirectories(validRelativePaths: validRelativePaths)
        } catch {
            logger.error("Failed to cleanup promise cache: \(String(describing: error), privacy: .public)")
        }
    }
}
