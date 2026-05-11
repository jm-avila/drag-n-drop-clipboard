import Foundation

public enum ShelfStoreError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}

public final class ShelfStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> ShelfState {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ShelfState()
        }

        let data = try Data(contentsOf: fileURL)
        let state = try decoder.decode(ShelfState.self, from: data)

        guard state.schemaVersion == ShelfState.currentSchemaVersion else {
            throw ShelfStoreError.unsupportedSchemaVersion(state.schemaVersion)
        }

        return state
    }

    public func save(_ state: ShelfState) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(state)
        let temporaryURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent(".")
            .appendingPathExtension("\(fileURL.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: temporaryURL, options: [.atomic])

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        try fileManager.moveItem(at: temporaryURL, to: fileURL)
    }
}
