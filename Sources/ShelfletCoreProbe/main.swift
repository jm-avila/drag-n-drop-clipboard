import CoreGraphics
import Foundation
import ShelfletCore

struct ProbeFailure: Error, CustomStringConvertible {
    let message: String

    var description: String {
        message
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw ProbeFailure(message: message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw ProbeFailure(message: "\(message). Expected \(expected), got \(actual)")
    }
}

@main
enum ShelfletCoreProbe {
    static func main() throws {
        var checkCount = 0

        try probeCacheManager(checkCount: &checkCount)
        try probeDragPolicies(checkCount: &checkCount)
        try probeScreenGeometry(checkCount: &checkCount)
        try probeShelfStore(checkCount: &checkCount)
        try probeSettingsStore(checkCount: &checkCount)

        print("ShelfletCoreProbe: passed \(checkCount) checks")
    }
}

private func probeCacheManager(checkCount: inout Int) throws {
    let root = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let manager = CacheManager(rootURL: root)
    let batchID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let directory = try manager.makePromiseBatchDirectory(id: batchID)

    try expect(FileManager.default.fileExists(atPath: directory.path), "promise batch directory should exist")
    checkCount += 1

    try expectEqual(
        try manager.relativePath(for: directory),
        "Promises/11111111-1111-1111-1111-111111111111",
        "promise batch relative path should be stable"
    )
    checkCount += 1

    do {
        _ = try manager.url(forRelativePath: "../outside.txt")
        throw ProbeFailure(message: "parent traversal relative path should be rejected")
    } catch CacheManagerError.invalidRelativePath("../outside.txt") {
        checkCount += 1
    }

    let outsideRoot = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: outsideRoot) }
    let outsideFile = outsideRoot.appendingPathComponent("outside.txt")
    try Data("outside".utf8).write(to: outsideFile)

    do {
        _ = try manager.relativePath(for: outsideFile)
        throw ProbeFailure(message: "absolute file outside cache should be rejected")
    } catch CacheManagerError.pathEscapesCache {
        checkCount += 1
    }
}

private func probeDragPolicies(checkCount: inout Int) throws {
    try expect(
        DragIntakePolicy.acceptedOperation(source: [.copy, .move], payload: DragPayloadSummary()).isEmpty,
        "unsupported payload should accept no operation"
    )
    checkCount += 1

    try expectEqual(
        DragIntakePolicy.acceptedOperation(source: [.copy, .move], payload: DragPayloadSummary(fileURLCount: 1)),
        .copy,
        "supported payload should prefer copy"
    )
    checkCount += 1

    try expectEqual(
        DragIntakePolicy.acceptedOperation(source: [.move], payload: DragPayloadSummary(filePromiseCount: 1)),
        .move,
        "supported payload should fall back to move"
    )
    checkCount += 1

    try expect(
        DragOutPolicy.shouldRemoveItem(outcome: .droppedAndAccepted, policy: .removeWhenDroppedAndAccepted),
        "accepted drag-out should remove only when policy allows it"
    )
    checkCount += 1

    try expect(
        !DragOutPolicy.shouldRemoveItem(outcome: .cancelled, policy: .removeWhenDroppedAndAccepted),
        "cancelled drag-out should not remove items"
    )
    checkCount += 1
}

private func probeScreenGeometry(checkCount: inout Int) throws {
    let screen = ScreenFrame(
        frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 10, y: 20, width: 900, height: 700)
    )
    try expectEqual(
        ShelfGeometry.hotZoneFrames(screen: screen, edge: .left, thickness: 8),
        [CGRect(x: 10, y: 20, width: 8, height: 700)],
        "left hot zone should use visible frame"
    )
    checkCount += 1

    let notchedScreen = ScreenFrame(
        frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 200, y: 0, width: 600, height: 780),
        auxiliaryTopLeftArea: CGRect(x: 0, y: 780, width: 180, height: 20),
        auxiliaryTopRightArea: CGRect(x: 820, y: 780, width: 180, height: 20)
    )
    let topFrames = ShelfGeometry.hotZoneFrames(screen: notchedScreen, edge: .top, thickness: 8)
    try expectEqual(topFrames.count, 3, "top hot zone should include visible and auxiliary strips")
    checkCount += 1
    try expect(!topFrames.contains { $0.width == 1000 }, "top hot zone should not span the physical frame")
    checkCount += 1
}

private func probeShelfStore(checkCount: inout Int) throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let store = ShelfStore(fileURL: directory.appendingPathComponent("shelf.json"))
    let item = ShelfItem(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        kind: .file,
        displayName: "example.pdf",
        storage: .bookmark(Data([1, 2, 3])),
        contentTypeIdentifier: "com.adobe.pdf",
        fileSize: 42,
        importedAt: Date(timeIntervalSince1970: 10),
        lastValidatedAt: Date(timeIntervalSince1970: 20),
        sourceApplication: "Finder",
        availability: .available
    )
    let state = ShelfState(items: [item])
    try store.save(state)
    try expectEqual(try store.load(), state, "shelf store should round-trip state")
    checkCount += 1

    let invalidFileURL = directory.appendingPathComponent("invalid-shelf.json")
    try Data("{\"schemaVersion\":999,\"items\":[]}".utf8).write(to: invalidFileURL)
    let invalidStore = ShelfStore(fileURL: invalidFileURL)
    do {
        _ = try invalidStore.load()
        throw ProbeFailure(message: "unsupported schema should be rejected")
    } catch ShelfStoreError.unsupportedSchemaVersion(999) {
        checkCount += 1
    }
}

private func probeSettingsStore(checkCount: inout Int) throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
    let settings = AppSettings(
        enabledEdges: [.left, .top],
        hotZoneThickness: 12,
        revealDelay: 0.3,
        showDockIcon: true,
        removeItemsAfterAcceptedDragOut: true
    )
    try store.save(settings)
    try expectEqual(try store.load(), settings, "settings store should round-trip settings")
    checkCount += 1
}

private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ShelfletCoreProbe")
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
