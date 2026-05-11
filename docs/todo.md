# Shelflet Implementation TODO

This checklist is the implementation guide for Shelflet, derived from `docs/specs.md`.

## Non-Negotiable Product Decisions

- [ ] Set the minimum supported OS to macOS 13 Ventura.
- [ ] Build the core shelf and drag surfaces in AppKit.
- [ ] Use SwiftUI only for settings, preferences, and simple menu-command UI.
- [ ] Ship as an agent-style utility by default using `LSUIElement`.
- [ ] Provide an optional troubleshooting mode to show a Dock icon.
- [ ] Use a menu-bar `NSStatusItem`, but do not make it the only recovery path.
- [ ] Use two distinct window surfaces: thin invisible edge destination windows and a visible shelf panel.
- [ ] Use `NSCollectionView` for shelf contents.
- [ ] Use Quick Look Thumbnailing for previews, with standard file icons as fallback.
- [ ] Treat file promises as first-class drag inputs.
- [ ] Always materialize file promises into Shelflet-owned cache storage before showing them as shelf items.
- [ ] Represent normal dragged-in files as referenced items backed by security-scoped bookmarks.
- [ ] Represent materialized promises as cached items owned by Shelflet.
- [ ] Keep the internal storage model sandbox-compatible from the start.
- [ ] Avoid Accessibility, Input Monitoring, broad file-system, USB, camera, or unrelated entitlements.
- [ ] Prefer restrained standard macOS visual materials over custom glass or heavy blur effects.

## Phase 0: Project Foundation

- [ ] Create a native macOS app project targeting macOS 13 or newer.
- [ ] Confirm Swift and Xcode versions supported by the project.
- [ ] Configure bundle metadata for a background utility app.
- [ ] Add `LSUIElement` to `Info.plist` for default agent behavior.
- [ ] Add a clear product name, bundle identifier, version, and copyright metadata.
- [ ] Decide early whether the initial distribution target is Mac App Store or direct Developer ID notarization.
- [ ] If targeting the Mac App Store, enable App Sandbox from the start.
- [ ] If targeting direct distribution first, enable hardened runtime and keep storage/bookmark design App-Store-compatible.
- [ ] Add the minimal entitlements needed for user-selected files.
- [ ] Prefer `com.apple.security.files.user-selected.read-only` unless write access is explicitly required.
- [ ] Use `com.apple.security.files.user-selected.read-write` only if export or move flows require it.
- [ ] Do not add unrelated entitlements.
- [ ] Establish app module boundaries: app shell, status item, windowing, drag core, persistence, thumbnailing, settings.
- [ ] Add a lightweight dependency injection/composition root for controllers and services.
- [ ] Add a logging strategy for drag classification, promise materialization, bookmark resolution, cache cleanup, and window placement.
- [ ] Add debug-only switches for inspecting hot-zone geometry and drag classification.
- [ ] Create a manual QA checklist directory or document for recorded certification runs.

## Phase 1: App Shell And Lifecycle

- [ ] Implement the main app entry point.
- [ ] Start without showing a main document window.
- [ ] Initialize the composition root at launch.
- [ ] Initialize the status-item controller at launch.
- [ ] Initialize the screen/window coordinator at launch.
- [ ] Initialize persistence before showing previously saved shelf items.
- [ ] Initialize cache directories before accepting promises.
- [ ] Restore persisted shelf state after services are ready.
- [ ] Handle app termination by flushing pending persistence writes.
- [ ] Handle app activation without unexpectedly showing the Dock or main window.
- [ ] Provide a global app command to show the shelf.
- [ ] Provide a global app command to hide the shelf.
- [ ] Provide a global app command to open settings.
- [ ] Provide a global app command to quit Shelflet.
- [ ] Add first-run onboarding state.
- [ ] Show a first-run hint explaining the edge trigger, status item, and recovery commands.
- [ ] Ensure the app can recover if the status item is hidden due to limited menu-bar space.

## Phase 2: Status Item And Menus

- [ ] Create an `NSStatusItem` through `NSStatusBar`.
- [ ] Add a simple, recognizable menu-bar icon.
- [ ] Provide an accessible label for the status item.
- [ ] Build a status menu with Show Shelf.
- [ ] Add Hide Shelf to the status menu.
- [ ] Add Open Settings to the status menu.
- [ ] Add Launch at Login state or shortcut to settings.
- [ ] Add Show Dock Icon troubleshooting toggle or route to settings.
- [ ] Add Quit to the status menu.
- [ ] Ensure menu actions work while the app is nonactivating.
- [ ] Ensure Show Shelf works even when no edge hot zone is currently visible.
- [ ] Ensure status item absence does not block keyboard/menu command recovery.
- [ ] Test behavior when the menu bar is crowded and the status item may be hidden.

## Phase 3: Screen And Geometry Model

- [ ] Build a `ScreenCoordinator` or equivalent service that owns screen bindings.
- [ ] Never use `NSScreen.main` to choose the drag target screen.
- [ ] Derive the target screen from the hot-zone window that received the drag.
- [ ] Derive shelf placement from the drag location relative to the destination window when needed.
- [ ] Read `NSScreen.screens` fresh when rebuilding geometry.
- [ ] Do not cache `NSScreen.screens` indefinitely.
- [ ] Observe `NSApplication.didChangeScreenParametersNotification`.
- [ ] Rebuild hot-zone windows when displays are attached.
- [ ] Rebuild hot-zone windows when displays are detached.
- [ ] Rebuild hot-zone windows when display resolution changes.
- [ ] Rebuild hot-zone windows when display scaling changes.
- [ ] Rebuild hot-zone windows when display arrangement changes.
- [ ] Reposition visible shelf panels after screen changes.
- [ ] Handle the case where a previously selected screen no longer exists.
- [ ] Clamp shelf frames to the current visible area.
- [ ] Use `visibleFrame` for normal shelf placement.
- [ ] Treat top-edge placement as notch-aware.
- [ ] For top-edge triggers, start from `visibleFrame` rather than physical `frame`.
- [ ] Include `auxiliaryTopLeftArea` and `auxiliaryTopRightArea` where appropriate on notched displays.
- [ ] Do not create a naive full-width top strip across the camera housing area.
- [ ] Define supported trigger edges for MVP.
- [ ] Configure default edge and thickness.
- [ ] Make hot-zone thickness tunable through debug configuration.
- [ ] Make reveal delay tunable through debug configuration.
- [ ] Make shelf offset and margin tunable through debug configuration.
- [ ] Test built-in display only.
- [ ] Test external display only.
- [ ] Test mirrored displays.
- [ ] Test extended displays.
- [ ] Test menu bar on a non-primary display.
- [ ] Test display changes while Shelflet is running.
- [ ] Test display changes while the shelf is visible.
- [ ] Test display changes while a drag is in progress.

## Phase 4: Edge Destination Windows

- [ ] Implement a separate invisible or nearly invisible edge destination window per active trigger edge and screen.
- [ ] Keep edge destination windows thin and conservative.
- [ ] Keep edge destination windows distinct from the visible shelf panel.
- [ ] Register dragged types directly on the destination view or window.
- [ ] Accept file URL pasteboard types.
- [ ] Accept file promise receiver pasteboard types.
- [ ] Reject unsupported payloads without showing the shelf.
- [ ] Configure window level appropriate for drag detection without disrupting normal use.
- [ ] Evaluate whether the hot-zone window needs overlay-like level behavior.
- [ ] Use `NSWindow.CollectionBehavior` deliberately for Spaces, full-screen, and Stage Manager.
- [ ] Use `canJoinAllApplications` for hot-zone overlay behavior on macOS 13+ where appropriate.
- [ ] Use `canJoinAllSpaces` only where needed and tested.
- [ ] Avoid forcing the hot-zone window into normal app activation behavior.
- [ ] Ensure the hot-zone does not steal normal clicks.
- [ ] Ensure the hot-zone does not activate the app on hover.
- [ ] Ensure the hot-zone does not visually flash during normal mouse movement.
- [ ] Ensure the hot-zone is discoverable only during compatible drag activity.
- [ ] Add debug rendering for hot-zone bounds.
- [ ] Add logs for hot-zone creation, screen assignment, and collection behavior.
- [ ] Verify Finder file drags enter the hot zone.
- [ ] Verify browser download/file drags enter the hot zone.
- [ ] Verify at least one promise-based source enters the hot zone.
- [ ] Verify unsupported drags do not reveal the shelf.
- [ ] Verify normal edge interactions remain usable.
- [ ] Verify Mission Control, Spaces, full-screen apps, and Stage Manager do not break hot-zone behavior.

## Phase 5: Drag Intake State Machine

- [ ] Implement drag intake as an explicit state machine.
- [ ] Model idle state.
- [ ] Model drag entered state.
- [ ] Model classified state.
- [ ] Model hovering/revealing state.
- [ ] Model preparing for drop state.
- [ ] Model importing state.
- [ ] Model accepted state.
- [ ] Model rejected state.
- [ ] Model cancelled state.
- [ ] Track AppKit drag sequence number or equivalent drag identity.
- [ ] Cache classification per drag sequence.
- [ ] Parse the pasteboard in `draggingEntered(_:)`.
- [ ] Avoid reparsing pasteboard contents in `draggingUpdated(_:)`.
- [ ] Use `draggingUpdated(_:)` only for hover affordances, reveal timing, and operation masks.
- [ ] Use `prepareForDragOperation(_:)` as the final pre-drop acceptance check.
- [ ] Use `performDragOperation(_:)` for actual import work.
- [ ] Return operation masks based on overlap between source allowed operations and Shelflet accepted operations.
- [ ] Classify payloads into file URLs.
- [ ] Classify payloads into folders.
- [ ] Classify payloads into packages.
- [ ] Classify payloads into file promises.
- [ ] Classify payloads into unsupported content.
- [ ] Distinguish file-system URLs from arbitrary web URLs.
- [ ] Use `NSPasteboard.canReadObject(forClasses:options:)` for file URL capability checks.
- [ ] Use `NSPasteboard.readObjects(forClasses:options:)` with `URL.self` for concrete file URLs.
- [ ] Use Uniform Type Identifier filtering where needed.
- [ ] Use `UTType.fileURL` / `public.file-url` semantics for file URL intake.
- [ ] Reject plain text, arbitrary URLs, and unsupported pasteboard data by default.
- [ ] Log classification results once per drag sequence.
- [ ] Log rejection reasons.
- [ ] Keep the UI responsive during classification.
- [ ] Ensure repeated `draggingUpdated(_:)` calls do not create duplicate items.
- [ ] Ensure leaving the hot zone resets hover/reveal state.
- [ ] Ensure cancelled drags leave no partial shelf items.

## Phase 6: Visible Shelf Panel

- [ ] Implement the visible shelf as an `NSPanel`.
- [ ] Use `.nonactivatingPanel` as the default style mask.
- [ ] Configure `becomesKeyOnlyIfNeeded` for keyboard interaction after explicit focus or click.
- [ ] Evaluate `isFloatingPanel` only after testing whether the shelf gets lost behind windows.
- [ ] Do not make the shelf panel the same window as the edge destination hot zone.
- [ ] Configure collection behavior for normal Spaces.
- [ ] Configure collection behavior for full-screen contexts.
- [ ] Use `fullScreenAuxiliary` where the shelf must appear with full-screen apps.
- [ ] Test whether `canJoinAllApplications` is appropriate for the visible shelf or only the hot zone.
- [ ] Prevent the shelf from unexpectedly activating Shelflet during drag reveal.
- [ ] Prevent the shelf from obscuring the likely drop destination during drag-out.
- [ ] Use `NSVisualEffectView` for the panel background.
- [ ] Choose semantic material based on role, not visual novelty.
- [ ] Avoid custom glass, excessive reflectivity, and heavy content-layer effects.
- [ ] Add a restrained border or shadow only if needed for contrast.
- [ ] Define collapsed/hidden state.
- [ ] Define visible/revealed state.
- [ ] Define drag-hover state.
- [ ] Define drop-accepted state.
- [ ] Define empty state.
- [ ] Define error state for failed imports.
- [ ] Add reveal animation after hot-zone hover if UX testing supports it.
- [ ] Add hide animation after cancellation or timeout if it does not hurt responsiveness.
- [ ] Keep animations secondary to drag reliability.
- [ ] Ensure panel layout works on small laptop screens.
- [ ] Ensure panel layout works on large external displays.
- [ ] Ensure panel layout works near the Dock.
- [ ] Ensure panel layout works near the menu bar.
- [ ] Ensure panel layout works with notched displays.

## Phase 7: Shelf Collection View

- [ ] Back the shelf contents with `NSCollectionView`.
- [ ] Define a collection-view item/cell for shelf items.
- [ ] Show thumbnail or icon.
- [ ] Show filename or display name.
- [ ] Show minimal metadata when helpful, such as file kind or unavailable state.
- [ ] Indicate cached versus referenced items only if useful for debugging or settings.
- [ ] Implement empty shelf state.
- [ ] Implement single selection.
- [ ] Implement multi-selection.
- [ ] Implement range selection if it fits collection-view behavior.
- [ ] Implement keyboard selection after explicit focus.
- [ ] Implement delete/remove from shelf.
- [ ] Implement context menu actions.
- [ ] Add Reveal in Finder for available file items.
- [ ] Add Remove from Shelf.
- [ ] Add Clear Shelf.
- [ ] Add Copy File or Drag Again only if it fits AppKit interaction cleanly.
- [ ] Support insert animations.
- [ ] Support remove animations.
- [ ] Support reorder or move animations only if reordering is in MVP.
- [ ] Keep the in-memory collection model separate from persisted storage.
- [ ] Ensure duplicate file drops have a defined behavior.
- [ ] Decide whether duplicates are allowed, merged, or surfaced as separate entries.
- [ ] Ensure unavailable referenced files show a recoverable state.
- [ ] Ensure missing cached files show a recoverable state.
- [ ] Ensure very long filenames do not break layout.
- [ ] Ensure many items remain usable.
- [ ] Add an item limit only if needed for performance or UX.

## Phase 8: Shelf Domain Model

- [ ] Define a stable `ShelfItem` identifier.
- [ ] Store item kind: referenced file, cached file, folder, package, or other supported file-system item.
- [ ] Store display name.
- [ ] Store original file URL metadata where safe.
- [ ] Store bookmark data for referenced items.
- [ ] Store cache-relative path for cached items.
- [ ] Store content type / UTI when available.
- [ ] Store file size when available.
- [ ] Store creation/import timestamp.
- [ ] Store last validation timestamp if useful.
- [ ] Store thumbnail cache key or thumbnail metadata if needed.
- [ ] Store source app metadata if available and useful for diagnostics.
- [ ] Store promise metadata for materialized promises if useful for compatibility debugging.
- [ ] Keep all persistent records versioned.
- [ ] Add a migration path for future schema changes.
- [ ] Keep references and cached files distinguishable in code.
- [ ] Make promise-backed items cached items after materialization.
- [ ] Do not keep long-lived half-materialized promise state in the visible shelf.
- [ ] Define import errors separately from final shelf items.
- [ ] Define item availability separately from item identity.
- [ ] Define removal policy separately from drag-out success.

## Phase 9: Concrete File URL Import

- [ ] Import concrete file URLs from the pasteboard.
- [ ] Accept regular files.
- [ ] Accept folders if folders are in MVP.
- [ ] Accept packages as packages rather than recursively expanding them by default.
- [ ] Decide whether aliases and symlinks are accepted.
- [ ] Resolve basic file metadata for display.
- [ ] Create security-scoped bookmarks for referenced items.
- [ ] Create bookmarks with `withSecurityScope`.
- [ ] Store bookmark data in persistence.
- [ ] Avoid eagerly reading large file contents on import.
- [ ] Generate display metadata without blocking the drag operation for too long.
- [ ] Handle files that disappear between classification and import.
- [ ] Handle permission failures gracefully.
- [ ] Handle malformed URLs gracefully.
- [ ] Handle duplicate URLs according to the chosen duplicate policy.
- [ ] Log successful imports.
- [ ] Log failed imports with actionable reason.
- [ ] Verify referenced files can be displayed immediately after import.
- [ ] Verify referenced files can be dragged back out immediately after import.

## Phase 10: File Promise Import

- [ ] Detect `NSFilePromiseReceiver` objects from the pasteboard.
- [ ] Accept file promises as first-class inputs.
- [ ] Create a Shelflet-owned cache directory for promised files.
- [ ] Create a unique destination directory per promise import batch.
- [ ] Use `receivePromisedFiles(atDestination:options:operationQueue:reader:)` to materialize promises.
- [ ] Run promise materialization on an operation queue, not the main thread.
- [ ] Keep UI responsive while promises are being written.
- [ ] Show temporary importing/progress state if materialization is not instant.
- [ ] Do not expose a promise as a normal shelf item until the file exists in cache.
- [ ] Convert materialized promise output into cached shelf items.
- [ ] Store cache-relative paths, not arbitrary absolute paths, where practical.
- [ ] Capture display metadata after materialization succeeds.
- [ ] Generate thumbnails after materialization succeeds.
- [ ] Handle promise writer failure.
- [ ] Handle partial promise batch failure.
- [ ] Handle zero files materialized.
- [ ] Handle duplicate promised filenames.
- [ ] Handle large promised files.
- [ ] Handle folders promised by source apps if encountered.
- [ ] Handle cancellation during materialization.
- [ ] Clean up failed or partial cache directories.
- [ ] Log source app and promise metadata where available.
- [ ] Maintain an internal compatibility matrix for promise sources.
- [ ] Test promise intake from Mail.
- [ ] Test promise intake from Safari if it provides relevant file promises.
- [ ] Test promise intake from Photos if available.
- [ ] Test at least one creative-app promise source if available.

## Phase 11: Persistence And Bookmark Lifecycle

- [ ] Choose a persistence format for shelf records.
- [ ] Keep persistence simple for MVP, such as JSON, property list, or lightweight database.
- [ ] Store persisted data inside the app container.
- [ ] Store cached files inside the app container.
- [ ] Use atomic writes for shelf metadata.
- [ ] Version the persistence schema.
- [ ] Load persisted items at launch.
- [ ] Validate persisted records during load.
- [ ] Resolve referenced item bookmarks only when needed.
- [ ] Resolve bookmarks with security-scope options.
- [ ] Detect stale bookmark flags on resolution.
- [ ] Rewrite stale bookmarks immediately after successful stale resolution.
- [ ] Call `startAccessingSecurityScopedResource()` only around actual file work.
- [ ] Always balance with `stopAccessingSecurityScopedResource()`.
- [ ] Scope security access tightly around metadata refresh, thumbnailing, drag export, and reveal operations.
- [ ] Do not keep security-scoped resources open for the whole app session unless proven necessary.
- [ ] Mark referenced items unavailable when bookmark resolution fails.
- [ ] Provide a UI affordance for unavailable referenced items.
- [ ] Preserve unavailable records unless the user removes them.
- [ ] Validate cached item files exist on load.
- [ ] Mark cached items unavailable or remove them according to cache policy if missing.
- [ ] Persist item ordering.
- [ ] Persist selection only if it improves UX.
- [ ] Persist user settings separately from shelf item records.
- [ ] Add backup-safe behavior for metadata files.
- [ ] Avoid persisting security-sensitive transient data.
- [ ] Explicitly test drag-arrived file bookmark access after relaunch in a sandboxed build.

## Phase 12: Cache Management

- [ ] Define cache root inside the app container.
- [ ] Define subdirectories for promised-file materialization.
- [ ] Define subdirectories for thumbnail cache if needed.
- [ ] Use unique names for materialized promise batches.
- [ ] Avoid filename collisions.
- [ ] Keep cache paths relative in persisted records where practical.
- [ ] Own cleanup for cached promise files.
- [ ] Remove cached files when the user removes the corresponding cached item if policy says removal means delete owned cache.
- [ ] Do not delete user-owned referenced files when removing referenced shelf items.
- [ ] Add Clear Shelf behavior that handles referenced and cached items correctly.
- [ ] Add cache cleanup for failed imports.
- [ ] Add startup cleanup for orphaned temporary promise directories.
- [ ] Add optional cleanup for orphaned cached files not referenced by metadata.
- [ ] Protect against deleting outside the app container.
- [ ] Log cache cleanup actions.
- [ ] Test cache cleanup after failed promise materialization.
- [ ] Test cache cleanup after item removal.
- [ ] Test cache cleanup after metadata corruption.

## Phase 13: Thumbnail And Icon Pipeline

- [ ] Use `QLThumbnailGenerator` for file thumbnails.
- [ ] Generate thumbnails asynchronously.
- [ ] Keep thumbnail generation off the main thread except UI updates.
- [ ] Use sensible target sizes for collection-view cells.
- [ ] Use scale-aware thumbnail requests.
- [ ] Cache generated thumbnails if repeated generation is expensive.
- [ ] Fall back to standard file icons when Quick Look fails.
- [ ] Fall back to standard file icons when thumbnailing would be wasteful.
- [ ] Fall back to folder/package icons for directories and packages as appropriate.
- [ ] Cancel thumbnail requests for removed items where possible.
- [ ] Avoid blocking drag import on thumbnail generation.
- [ ] Refresh thumbnails when files change only if needed for MVP.
- [ ] Handle unavailable referenced files with a missing/unavailable icon state.
- [ ] Handle thumbnail failures without failing the item import.
- [ ] Test common image files.
- [ ] Test PDFs.
- [ ] Test text/code files.
- [ ] Test folders.
- [ ] Test packages.
- [ ] Test large files.
- [ ] Test unavailable files.

## Phase 14: Drag Export From Shelf

- [ ] Implement drag-out from collection-view items.
- [ ] Support dragging one selected item.
- [ ] Support dragging multiple selected items as a group.
- [ ] Re-export real file URLs whenever possible.
- [ ] For cached promise-backed items, export the cached file URL.
- [ ] For referenced items, resolve bookmark and export the resolved file URL.
- [ ] Avoid creating fresh file promises for drag-out in MVP unless a concrete need appears.
- [ ] Use `beginDraggingSession(with:event:source:)` to start drags.
- [ ] Account for the drag beginning on the next run-loop turn.
- [ ] Implement `NSDraggingSource` behavior for shelf item views.
- [ ] Implement `draggingSession(_:sourceOperationMaskFor:)`.
- [ ] Return appropriate operation masks for copy, move, and link expectations.
- [ ] Use `shouldDelayWindowOrdering(for:)` so drag-out does not activate or reorder the shelf in a disruptive way.
- [ ] Prevent the shelf from covering the destination during drag-out.
- [ ] Define drag-out outcome model: dropped and accepted.
- [ ] Define drag-out outcome model: cancelled.
- [ ] Define drag-out outcome model: dropped but destination failed or ignored.
- [ ] Do not infer physical file movement solely from visual drop completion.
- [ ] Treat shelf item removal after drag-out as explicit UI policy.
- [ ] Decide whether items remain in the shelf after successful drag-out for MVP.
- [ ] If auto-removing after drag-out, make the behavior preference-backed or clearly communicated.
- [ ] Do not delete cached files merely because a destination appeared to accept a drag unless policy explicitly says so.
- [ ] Handle missing referenced files during drag-out.
- [ ] Handle missing cached files during drag-out.
- [ ] Handle bookmark resolution failure during drag-out.
- [ ] Log drag-out start, operation mask, and final AppKit callback outcome.
- [ ] Test drag-out into Finder.
- [ ] Test drag-out into a non-Finder document target.
- [ ] Test drag-out into an app that rejects the drop.
- [ ] Test drag-out cancellation with Escape.
- [ ] Test drag-out cancellation by releasing over invalid space.
- [ ] Test multi-item drag-out.

## Phase 15: Settings UI

- [ ] Build settings in SwiftUI.
- [ ] Add General settings.
- [ ] Add launch-at-login setting.
- [ ] Add launch-at-login status display.
- [ ] Use `SMAppService.mainApp` for modern launch-at-login behavior.
- [ ] Implement register through `SMAppService.register()`.
- [ ] Implement unregister through `SMAppService.unregister()`.
- [ ] Display `.enabled` state clearly.
- [ ] Display `.notRegistered` state clearly.
- [ ] Display `.requiresApproval` state clearly.
- [ ] Provide help text or link explaining where approval lives in System Settings.
- [ ] Add Show Dock Icon troubleshooting setting.
- [ ] Add edge selection setting if more than one edge is supported.
- [ ] Add hot-zone sensitivity/thickness setting only if needed after testing.
- [ ] Add reveal delay setting only if needed after testing.
- [ ] Add Clear Shelf action.
- [ ] Add Clear Cached Files action if different from Clear Shelf.
- [ ] Add cache size display if cache growth becomes user-visible.
- [ ] Add About or diagnostics section.
- [ ] Add compatibility/debug export only for development builds unless needed for support.
- [ ] Persist settings separately from shelf items.
- [ ] Ensure settings can be opened from the status menu.
- [ ] Ensure settings can be opened when the app is otherwise hidden.

## Phase 16: Keyboard And Commands

- [ ] Add command to show shelf.
- [ ] Add command to hide shelf.
- [ ] Add command to toggle shelf if useful.
- [ ] Add command to open settings.
- [ ] Add command to clear shelf with confirmation.
- [ ] Add command to remove selected items when the shelf has focus.
- [ ] Add Escape behavior to hide shelf or cancel focus state.
- [ ] Add keyboard navigation only after explicit shelf focus.
- [ ] Avoid global keyboard shortcuts in MVP unless explicitly required.
- [ ] Avoid Accessibility/Input Monitoring dependencies for shortcuts.
- [ ] Ensure commands do not force unwanted app activation.
- [ ] Ensure command availability reflects current shelf state.

## Phase 17: Error Handling And Diagnostics

- [ ] Define user-facing error states for failed imports.
- [ ] Define user-facing error states for failed promise materialization.
- [ ] Define user-facing error states for missing referenced files.
- [ ] Define user-facing error states for missing cached files.
- [ ] Define user-facing error states for bookmark resolution failure.
- [ ] Define user-facing error states for cache write failure.
- [ ] Keep transient drag rejection silent unless debugging.
- [ ] Show actionable errors only when the user expected an import or export to happen.
- [ ] Add structured logs for drag classification.
- [ ] Add structured logs for operation masks.
- [ ] Add structured logs for promise materialization.
- [ ] Add structured logs for bookmark resolution and stale bookmark rewrites.
- [ ] Add structured logs for cache cleanup.
- [ ] Add structured logs for screen/window placement decisions.
- [ ] Add a debug mode to show hot-zone bounds.
- [ ] Add a debug mode to dump current screens and shelf placement.
- [ ] Add a debug mode to dump current shelf item records without exposing sensitive bookmark data.
- [ ] Ensure logs do not leak private file contents.
- [ ] Avoid logging full paths in release builds unless needed and acceptable.

## Phase 18: Spaces, Full Screen, And Stage Manager Certification

- [ ] Build a compatibility matrix for normal desktop Spaces.
- [ ] Build a compatibility matrix for multiple Spaces.
- [ ] Build a compatibility matrix for full-screen apps.
- [ ] Build a compatibility matrix for Stage Manager on macOS 13+.
- [ ] Test hot-zone drag detection in a normal Space.
- [ ] Test visible shelf reveal in a normal Space.
- [ ] Test drag import in a normal Space.
- [ ] Test drag export in a normal Space.
- [ ] Test hot-zone drag detection over a full-screen app.
- [ ] Test visible shelf reveal over a full-screen app.
- [ ] Test drag import over a full-screen app.
- [ ] Test drag export from a full-screen context.
- [ ] Test hot-zone behavior with Stage Manager enabled.
- [ ] Test visible shelf behavior with Stage Manager enabled.
- [ ] Test that Shelflet windows do not incorrectly join Stage Manager groups.
- [ ] Test that Shelflet windows do not disappear behind Stage Manager unexpectedly.
- [ ] Adjust `NSWindow.CollectionBehavior` based on observed behavior.
- [ ] Document final chosen collection behaviors for hot-zone windows.
- [ ] Document final chosen collection behaviors for visible shelf panels.

## Phase 19: Sandboxing And Distribution Validation

- [ ] Build and run with App Sandbox enabled if Mac App Store is a target.
- [ ] Verify Finder file drag-in works in sandbox.
- [ ] Verify browser/download file drag-in works in sandbox.
- [ ] Verify file promise drag-in works in sandbox.
- [ ] Verify bookmark creation from drag-arrived file URLs works in sandbox.
- [ ] Verify bookmark resolution after app relaunch works in sandbox.
- [ ] Verify stale bookmark rewrite path works or is safely handled.
- [ ] Verify referenced item drag-out works after relaunch in sandbox.
- [ ] Verify cached promise item drag-out works after relaunch in sandbox.
- [ ] Verify cache write permissions inside the app container.
- [ ] Verify no broad file-system permission is required.
- [ ] Verify notarized direct build if direct distribution is selected.
- [ ] Verify hardened runtime settings if direct distribution is selected.
- [ ] Verify Mac App Store entitlement profile if store distribution is selected.
- [ ] Document final distribution decision and required signing settings.

## Phase 20: MVP Manual QA Gate

- [ ] Record a QA run for Finder file URL intake.
- [ ] Record a QA run for browser download/file intake.
- [ ] Record a QA run for one promise-based source app.
- [ ] Record a QA run for drag-out into Finder.
- [ ] Record a QA run for drag-out into one non-Finder document target.
- [ ] Record a QA run for relaunch with a valid bookmark-backed referenced item.
- [ ] Record a QA run for relaunch with a valid cached promise-backed item.
- [ ] Record a QA run for display configuration changes mid-session.
- [ ] Record a QA run for display configuration changes while shelf is visible.
- [ ] Record a QA run for display configuration changes during or immediately after drag activity.
- [ ] Record a QA run for full-screen app behavior.
- [ ] Record a QA run for Stage Manager behavior.
- [ ] Record a QA run for top-edge behavior on a notched display if top edge is supported.
- [ ] Record a QA run for status item recovery.
- [ ] Record a QA run for Show Shelf command recovery.
- [ ] Record a QA run for launch-at-login settings and approval state.
- [ ] Record a QA run for unavailable referenced file behavior.
- [ ] Record a QA run for failed promise materialization if reproducible.

## Phase 21: Automated Tests

- [ ] Add unit tests for shelf item model encoding and decoding.
- [ ] Add unit tests for persistence schema version handling.
- [ ] Add unit tests for duplicate item policy.
- [ ] Add unit tests for cache path generation.
- [ ] Add unit tests preventing cache deletion outside the app container.
- [ ] Add unit tests for bookmark wrapper behavior with mocked resolver where possible.
- [ ] Add unit tests for stale bookmark handling paths where possible.
- [ ] Add unit tests for drag classification with mocked pasteboard abstractions.
- [ ] Add unit tests for unsupported payload rejection.
- [ ] Add unit tests for operation-mask decision logic.
- [ ] Add unit tests for drag-out outcome policy.
- [ ] Add unit tests for screen placement calculations.
- [ ] Add unit tests for notch-aware top-edge geometry with mocked screen data.
- [ ] Add unit tests for shelf frame clamping.
- [ ] Add unit tests for settings persistence.
- [ ] Add integration tests for persistence load/save if practical.
- [ ] Add integration tests for cache cleanup if practical.
- [ ] Add UI tests only for stable settings and command surfaces.
- [ ] Keep manual QA as the authority for real AppKit drag-and-drop behavior.

## Phase 22: Performance And Reliability Checks

- [ ] Ensure drag hover does not parse pasteboard repeatedly.
- [ ] Ensure drag reveal latency feels immediate after classification.
- [ ] Ensure promise materialization does not block the main thread.
- [ ] Ensure thumbnail generation does not block the main thread.
- [ ] Ensure persistence writes are batched or atomic enough to avoid corruption.
- [ ] Ensure shelf restore is fast with a realistic number of items.
- [ ] Test with many small files.
- [ ] Test with one very large file.
- [ ] Test with a large promised file.
- [ ] Test with slow external or cloud-backed files if available.
- [ ] Test with files that disappear during import.
- [ ] Test with files that disappear after relaunch.
- [ ] Test with cache directory manually damaged in development.
- [ ] Test with corrupted metadata in development.
- [ ] Confirm memory usage remains reasonable after repeated thumbnail generation.
- [ ] Confirm no long-lived security-scoped access leaks.
- [ ] Confirm no orphaned temporary promise directories accumulate during normal use.

## Phase 23: UX Polish After Risk Retirement

- [ ] Polish shelf reveal only after edge drag intake is reliable.
- [ ] Polish collection-view animations only after import/export semantics are stable.
- [ ] Polish visual materials only after windowing behavior is stable.
- [ ] Add subtle hover affordance during valid drags.
- [ ] Add clear rejected-drag affordance only if users need feedback.
- [ ] Add import progress affordance for slow promises.
- [ ] Add unavailable item affordance.
- [ ] Add empty-state copy that explains how to use the shelf.
- [ ] Add first-run onboarding hint.
- [ ] Add concise settings help for launch at login approval.
- [ ] Add app icon and menu-bar icon polish.
- [ ] Add accessibility labels for interactive controls.
- [ ] Add VoiceOver-friendly labels for shelf items where practical.
- [ ] Verify reduced motion settings if animations are significant.
- [ ] Verify dark mode.
- [ ] Verify light mode.
- [ ] Verify high contrast or increased contrast where practical.

## Phase 24: Documentation

- [ ] Document app architecture.
- [ ] Document why the shelf uses AppKit instead of SwiftUI.
- [ ] Document the two-window topology.
- [ ] Document the drag intake state machine.
- [ ] Document file URL versus file promise handling.
- [ ] Document referenced versus cached item storage.
- [ ] Document security-scoped bookmark lifecycle.
- [ ] Document cache cleanup policy.
- [ ] Document window collection behaviors.
- [ ] Document notch-aware screen geometry.
- [ ] Document distribution choice and entitlements.
- [ ] Document manual QA matrix and recorded run locations.
- [ ] Document known file-promise compatibility results.
- [ ] Document open questions that remain after MVP.

## Open Questions To Resolve During Implementation

- [ ] Certify sandbox behavior for drag-arrived external file references across app relaunch.
- [ ] Decide the final direct distribution versus Mac App Store path.
- [ ] Decide whether the MVP supports one edge or multiple edges.
- [ ] Decide whether top-edge support ships in MVP or waits until notch behavior is fully certified.
- [ ] Decide how thick the hot zone can be without interfering with normal edge interactions.
- [ ] Decide reveal delay based on real drag testing.
- [ ] Decide final window level for hot-zone windows.
- [ ] Decide final window level for the visible shelf panel.
- [ ] Decide whether `isFloatingPanel` is needed for the visible shelf.
- [ ] Decide whether successful drag-out removes items from the shelf or leaves them in place.
- [ ] Decide duplicate item behavior.
- [ ] Decide whether folders are accepted in MVP.
- [ ] Decide whether aliases and symlinks are accepted in MVP.
- [ ] Decide how broad the file promise compatibility matrix must be before shipping.
- [ ] Decide whether cache size controls are necessary for MVP.

## MVP Ship Criteria

- [ ] Finder file URL intake works.
- [ ] Browser/download file intake works.
- [ ] At least one promise-based source app works.
- [ ] File promises materialize into Shelflet-owned cache storage.
- [ ] Drag-out into Finder works.
- [ ] Drag-out into one non-Finder document target works.
- [ ] Relaunch restores a valid bookmark-backed referenced item.
- [ ] Relaunch restores a valid cached promise-backed item.
- [ ] Display configuration changes do not break hot-zone or shelf placement.
- [ ] Full-screen app behavior is tested and acceptable.
- [ ] Stage Manager behavior is tested and acceptable.
- [ ] Security-scoped bookmark lifecycle is implemented and verified.
- [ ] Cache cleanup does not delete user-owned referenced files.
- [ ] Status item and Show Shelf command both work as recovery paths.
- [ ] Launch-at-login setting shows accurate `SMAppService` status.
- [ ] Entitlements are minimal and documented.
- [ ] Manual QA recordings exist for the required flows.
- [ ] Known limitations and unsupported sources are documented.
