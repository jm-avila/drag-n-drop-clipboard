import AppKit

final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let showShelfAction: () -> Void
    private let hideShelfAction: () -> Void
    private let showSettingsAction: () -> Void
    private let clearShelfAction: () -> Void

    init(
        showShelf: @escaping () -> Void,
        hideShelf: @escaping () -> Void,
        showSettings: @escaping () -> Void,
        clearShelf: @escaping () -> Void
    ) {
        self.showShelfAction = showShelf
        self.hideShelfAction = hideShelf
        self.showSettingsAction = showSettings
        self.clearShelfAction = clearShelf
        super.init()
    }

    func start() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.full", accessibilityDescription: "Shelflet")
            button.toolTip = "Shelflet"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Shelf", action: #selector(showShelf), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Shelf", action: #selector(hideShelf), keyEquivalent: "h"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Clear Shelf", action: #selector(clearShelf), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Shelflet", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func showShelf() {
        showShelfAction()
    }

    @objc private func hideShelf() {
        hideShelfAction()
    }

    @objc private func showSettings() {
        showSettingsAction()
    }

    @objc private func clearShelf() {
        clearShelfAction()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
