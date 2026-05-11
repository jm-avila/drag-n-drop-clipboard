# Shelflet

Shelflet is a macOS 13+ AppKit shelf utility for temporarily holding files dragged to a screen edge.

## Build

```sh
make build
```

## Test

This toolchain does not expose `XCTest` or Swift Testing modules, so core tests are implemented as a headless executable probe suite.

```sh
make test
```

Expected output:

```text
ShelfletCoreProbe: passed 15 checks
```

## Package App Bundle

```sh
make app
```

The generated bundle is `.build/Shelflet.app` and uses `Packaging/Info.plist`, including `LSUIElement` for agent-style behavior.

## Run

```sh
make run-app
```

## Implemented MVP

- AppKit app shell with menu-bar status item.
- AppKit edge hot-zone windows separate from the visible shelf panel.
- Nonactivating `NSPanel` shelf backed by `NSCollectionView`.
- Drag intake state machine for file URLs and `NSFilePromiseReceiver` objects.
- Promise materialization into Shelflet-owned cache storage.
- Referenced file items backed by security-scoped bookmarks.
- Cached promise-backed items with cache-relative paths.
- Drag-out of shelf items as real file URLs.
- Quick Look thumbnail generation with file-icon fallback.
- SwiftUI settings for edge selection, hot-zone tuning, launch at login, Dock icon mode, and drag-out removal policy.
- Screen placement based on the receiving hot-zone screen, not `NSScreen.main`.
- Notch-aware top-edge geometry using visible and auxiliary top areas.
- App bundle metadata and minimal sandbox entitlements template.

## Manual QA Required

- Finder file URL intake.
- Browser/download file intake.
- Promise intake from Mail, Safari, Photos, and one creative app.
- Drag-out into Finder.
- Drag-out into a non-Finder document target.
- Relaunch restore for bookmark-backed referenced items.
- Relaunch restore for cached promise-backed items.
- Display configuration changes during runtime.
- Full-screen app behavior.
- Stage Manager behavior.
- Sandboxed bookmark access after relaunch.
