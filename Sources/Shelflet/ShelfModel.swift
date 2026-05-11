import Foundation
import OSLog
import ShelfletCore

@MainActor
final class ShelfModel {
    private let store: ShelfStore
    private let logger = Logger(subsystem: "Shelflet", category: "ShelfModel")

    private(set) var items: [ShelfItem] = [] {
        didSet {
            onChange?(items)
        }
    }

    var onChange: (([ShelfItem]) -> Void)?

    init(store: ShelfStore) {
        self.store = store
    }

    func load() {
        do {
            items = try store.load().items
            logger.info("Loaded \(self.items.count, privacy: .public) shelf items")
        } catch {
            items = []
            logger.error("Failed to load shelf state: \(String(describing: error), privacy: .public)")
        }
    }

    func add(_ newItems: [ShelfItem]) {
        guard !newItems.isEmpty else {
            return
        }

        items.append(contentsOf: newItems)
        persist()
    }

    func remove(ids: Set<UUID>) -> [ShelfItem] {
        let removed = items.filter { ids.contains($0.id) }
        items.removeAll { ids.contains($0.id) }
        persist()
        return removed
    }

    func clear() -> [ShelfItem] {
        let removed = items
        items = []
        persist()
        return removed
    }

    func updateBookmark(id: UUID, bookmarkData: Data) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items[index].storage = .bookmark(bookmarkData)
        items[index].lastValidatedAt = Date()
        items[index].availability = .available
        persist()
    }

    func updateAvailability(id: UUID, availability: ShelfItemAvailability) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items[index].availability = availability
        items[index].lastValidatedAt = Date()
        persist()
    }

    private func persist() {
        do {
            try store.save(ShelfState(items: items))
        } catch {
            logger.error("Failed to save shelf state: \(String(describing: error), privacy: .public)")
        }
    }
}
