import Foundation
import OSLog

struct SecurityScopedURL {
    let url: URL
    let isStale: Bool

    private let stopHandler: () -> Void

    init(url: URL, isStale: Bool, didStartAccessing: Bool) {
        self.url = url
        self.isStale = isStale
        self.stopHandler = {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    func stopAccessing() {
        stopHandler()
    }
}

final class BookmarkService {
    private let logger = Logger(subsystem: "Shelflet", category: "Bookmarks")

    func bookmarkData(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolve(_ bookmarkData: Data) throws -> SecurityScopedURL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        if isStale {
            logger.info("Resolved stale bookmark for \(url.lastPathComponent, privacy: .public)")
        }

        return SecurityScopedURL(url: url, isStale: isStale, didStartAccessing: didStartAccessing)
    }
}
