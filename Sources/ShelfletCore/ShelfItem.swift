import Foundation

public enum ShelfItemKind: String, Codable, Equatable, Sendable {
    case file
    case folder
    case package
}

public enum ShelfItemAvailability: String, Codable, Equatable, Sendable {
    case available
    case missing
    case unresolved
}

public enum ShelfItemStorage: Codable, Equatable, Sendable {
    case bookmark(Data)
    case cached(relativePath: String)

    public var cachedRelativePath: String? {
        if case let .cached(relativePath) = self {
            return relativePath
        }
        return nil
    }
}

public struct ShelfItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var kind: ShelfItemKind
    public var displayName: String
    public var storage: ShelfItemStorage
    public var contentTypeIdentifier: String?
    public var fileSize: Int64?
    public var importedAt: Date
    public var lastValidatedAt: Date?
    public var sourceApplication: String?
    public var promiseTypeIdentifier: String?
    public var availability: ShelfItemAvailability

    public init(
        id: UUID = UUID(),
        kind: ShelfItemKind,
        displayName: String,
        storage: ShelfItemStorage,
        contentTypeIdentifier: String? = nil,
        fileSize: Int64? = nil,
        importedAt: Date = Date(),
        lastValidatedAt: Date? = nil,
        sourceApplication: String? = nil,
        promiseTypeIdentifier: String? = nil,
        availability: ShelfItemAvailability = .available
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.storage = storage
        self.contentTypeIdentifier = contentTypeIdentifier
        self.fileSize = fileSize
        self.importedAt = importedAt
        self.lastValidatedAt = lastValidatedAt
        self.sourceApplication = sourceApplication
        self.promiseTypeIdentifier = promiseTypeIdentifier
        self.availability = availability
    }
}

public struct ShelfState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var items: [ShelfItem]

    public init(schemaVersion: Int = Self.currentSchemaVersion, items: [ShelfItem] = []) {
        self.schemaVersion = schemaVersion
        self.items = items
    }
}
