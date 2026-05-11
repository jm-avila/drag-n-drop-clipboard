import CoreGraphics
import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var enabledEdges: [ShelfEdge]
    public var hotZoneThickness: CGFloat
    public var revealDelay: TimeInterval
    public var showDockIcon: Bool
    public var removeItemsAfterAcceptedDragOut: Bool

    public init(
        enabledEdges: [ShelfEdge] = [.right],
        hotZoneThickness: CGFloat = 8,
        revealDelay: TimeInterval = 0.12,
        showDockIcon: Bool = false,
        removeItemsAfterAcceptedDragOut: Bool = false
    ) {
        self.enabledEdges = enabledEdges
        self.hotZoneThickness = hotZoneThickness
        self.revealDelay = revealDelay
        self.showDockIcon = showDockIcon
        self.removeItemsAfterAcceptedDragOut = removeItemsAfterAcceptedDragOut
    }
}

public final class SettingsStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
    }

    public func load() throws -> AppSettings {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return AppSettings()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(AppSettings.self, from: data)
    }

    public func save(_ settings: AppSettings) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(settings)
        try data.write(to: fileURL, options: [.atomic])
    }
}
