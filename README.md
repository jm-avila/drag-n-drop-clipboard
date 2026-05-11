# Shelflet

Shelflet is a macOS 13+ AppKit shelf utility for temporarily holding files dragged to a screen edge.

## Requirements

- macOS 13 Ventura or newer.
- Xcode Command Line Tools with Swift installed.
- `make` available from the terminal.

## Quick Start

From the repository root:

```sh
make run-app
```

This builds `.build/Shelflet.app` and opens it.

Shelflet is an agent-style menu-bar app. It does not open a normal Dock window by default. Look for the Shelflet tray icon in the macOS menu bar.

## How To Use

1. Run `make run-app`.
2. Move the cursor to the configured shelf edge. The default edge is the right side of the screen.
3. The shelf appears automatically when the cursor reaches that edge.
4. Drag files or selected text onto the shelf to store them temporarily.
5. Drag items from the shelf back into Finder or another app to export them.
6. Move the cursor away from the shelf and it hides automatically after a short delay.

The menu-bar icon provides these actions:

```text
Show Shelf
Hide Shelf
Clear Shelf
Settings...
Quit Shelflet
```

Use `Settings...` to change the active edge, adjust hot-zone thickness, tune reveal delay, enable launch at login, or show a Dock icon.

## Supported Items

Shelflet accepts regular file drags from Finder and compatible apps. This includes:

- Audio files
- Video files
- Text and code files
- Images
- PDFs
- Folders and packages
- File promises from apps such as Mail, Safari, Photos, and other apps that expose promised files

Shelflet also accepts selected plain text dragged from apps. Text snippets are saved into Shelflet's cache as `.txt` files, so they can be dragged back out like normal files.

## Stop The App

Use the menu-bar `Quit Shelflet` action, or run:

```sh
pkill Shelflet
```

## Development Commands

### Build

```sh
make build
```

### Test

This toolchain does not expose `XCTest` or Swift Testing modules, so core tests are implemented as a headless executable probe suite.

```sh
make test
```

Expected output:

```text
ShelfletCoreProbe: passed 18 checks
```

### Package App Bundle

```sh
make app
```

The generated bundle is `.build/Shelflet.app` and uses `Packaging/Info.plist`, including `LSUIElement` for agent-style behavior.

### Run Packaged App

```sh
open .build/Shelflet.app
```

## Troubleshooting

- If nothing appears, check the macOS menu bar for the Shelflet icon.
- If the shelf is hard to trigger, open `Settings...` and increase hot-zone thickness.
- If the menu-bar icon is hidden due to limited menu-bar space, run `pkill Shelflet`, then run `make run-app` again and enable `Show Dock icon` in settings.
- If an old build seems to be running, restart with `pkill Shelflet` followed by `make run-app`.

## Implemented MVP

- AppKit app shell with menu-bar status item.
- AppKit edge hot-zone windows separate from the visible shelf panel.
- Nonactivating `NSPanel` shelf backed by `NSCollectionView`.
- Drag intake state machine for file URLs and `NSFilePromiseReceiver` objects.
- Plain-text drag intake saved as cached `.txt` files.
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
- Plain-text selection intake.
- Promise intake from Mail, Safari, Photos, and one creative app.
- Drag-out into Finder.
- Drag-out into a non-Finder document target.
- Relaunch restore for bookmark-backed referenced items.
- Relaunch restore for cached promise-backed items.
- Display configuration changes during runtime.
- Full-screen app behavior.
- Stage Manager behavior.
- Sandboxed bookmark access after relaunch.
