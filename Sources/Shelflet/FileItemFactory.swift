import Foundation
import ShelfletCore
import UniformTypeIdentifiers

final class FileItemFactory {
    private let bookmarkService: BookmarkService
    private let cacheManager: CacheManager

    init(bookmarkService: BookmarkService, cacheManager: CacheManager) {
        self.bookmarkService = bookmarkService
        self.cacheManager = cacheManager
    }

    func makeReferencedItem(from url: URL, sourceApplication: String?) throws -> ShelfItem {
        let values = try resourceValues(for: url)
        let bookmarkData = try bookmarkService.bookmarkData(for: url)

        return ShelfItem(
            kind: kind(for: values),
            displayName: displayName(for: url, values: values),
            storage: .bookmark(bookmarkData),
            contentTypeIdentifier: values.contentType?.identifier,
            fileSize: Int64(values.fileSize ?? 0),
            sourceApplication: sourceApplication
        )
    }

    func makeCachedItem(from url: URL, sourceApplication: String?, promiseTypeIdentifier: String?) throws -> ShelfItem {
        let values = try resourceValues(for: url)
        let relativePath = try cacheManager.relativePath(for: url)

        return ShelfItem(
            kind: kind(for: values),
            displayName: displayName(for: url, values: values),
            storage: .cached(relativePath: relativePath),
            contentTypeIdentifier: values.contentType?.identifier,
            fileSize: Int64(values.fileSize ?? 0),
            sourceApplication: sourceApplication,
            promiseTypeIdentifier: promiseTypeIdentifier
        )
    }

    private func resourceValues(for url: URL) throws -> URLResourceValues {
        try url.resourceValues(forKeys: [
            .contentTypeKey,
            .fileSizeKey,
            .isDirectoryKey,
            .isPackageKey,
            .localizedNameKey
        ])
    }

    private func displayName(for url: URL, values: URLResourceValues) -> String {
        values.localizedName ?? url.lastPathComponent
    }

    private func kind(for values: URLResourceValues) -> ShelfItemKind {
        if values.isPackage == true {
            return .package
        }

        if values.isDirectory == true {
            return .folder
        }

        return .file
    }
}
