import Foundation

public enum CacheManagerError: Error, Equatable {
    case invalidRelativePath(String)
    case pathEscapesCache(URL)
}

public final class CacheManager {
    public let rootURL: URL
    private let fileManager: FileManager

    public init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL.standardizedFileURL
        self.fileManager = fileManager
    }

    public func ensureRootExists() throws {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    public func makePromiseBatchDirectory(id: UUID = UUID()) throws -> URL {
        try ensureRootExists()

        let directory = rootURL
            .appendingPathComponent("Promises", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
            .standardizedFileURL

        try validateInsideRoot(directory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public func relativePath(for fileURL: URL) throws -> String {
        let standardizedRoot = rootURL.standardizedFileURL.path
        let standardizedPath = fileURL.standardizedFileURL.path

        guard standardizedPath.hasPrefix(standardizedRoot + "/") else {
            throw CacheManagerError.pathEscapesCache(fileURL)
        }

        return String(standardizedPath.dropFirst(standardizedRoot.count + 1))
    }

    public func url(forRelativePath relativePath: String) throws -> URL {
        try validate(relativePath: relativePath)
        let url = rootURL.appendingPathComponent(relativePath).standardizedFileURL
        try validateInsideRoot(url)
        return url
    }

    public func removeCachedItem(relativePath: String) throws {
        let url = try url(forRelativePath: relativePath)

        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
    }

    public func cleanupTemporaryPromiseDirectories(validRelativePaths: Set<String>) throws {
        let promisesRoot = rootURL.appendingPathComponent("Promises", isDirectory: true)
        guard fileManager.fileExists(atPath: promisesRoot.path) else {
            return
        }

        let children = try fileManager.contentsOfDirectory(
            at: promisesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for child in children {
            let relativePath = try relativePath(for: child)
            if !validRelativePaths.contains(where: { $0 == relativePath || $0.hasPrefix(relativePath + "/") }) {
                try fileManager.removeItem(at: child)
            }
        }
    }

    private func validate(relativePath: String) throws {
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false)
        let isInvalid = relativePath.isEmpty
            || relativePath.hasPrefix("/")
            || components.contains("..")
            || components.contains(".")

        if isInvalid {
            throw CacheManagerError.invalidRelativePath(relativePath)
        }
    }

    private func validateInsideRoot(_ url: URL) throws {
        let rootPath = rootURL.standardizedFileURL.path
        let candidatePath = url.standardizedFileURL.path

        guard candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/") else {
            throw CacheManagerError.pathEscapesCache(url)
        }
    }
}
