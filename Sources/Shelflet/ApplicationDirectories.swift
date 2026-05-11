import Foundation

enum ApplicationDirectories {
    static let applicationName = "Shelflet"

    static var applicationSupportRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(applicationName, isDirectory: true)
    }

    static var shelfStoreURL: URL {
        applicationSupportRoot.appendingPathComponent("shelf.json")
    }

    static var settingsStoreURL: URL {
        applicationSupportRoot.appendingPathComponent("settings.json")
    }

    static var cacheRootURL: URL {
        applicationSupportRoot.appendingPathComponent("Cache", isDirectory: true)
    }
}
