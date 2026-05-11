import AppKit
import Combine
import ServiceManagement
import ShelfletCore
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            persist()
            onSettingsChanged?(settings)
        }
    }

    @Published private(set) var loginItemStatus: SMAppService.Status
    @Published private(set) var lastLoginItemError: String?

    var onSettingsChanged: ((AppSettings) -> Void)?
    var onClearShelf: (() -> Void)?

    private let store: SettingsStore

    init(settings: AppSettings, store: SettingsStore) {
        self.settings = settings
        self.store = store
        self.loginItemStatus = SMAppService.mainApp.status
    }

    var launchAtLoginEnabled: Bool {
        loginItemStatus == .enabled
    }

    var launchAtLoginRequiresApproval: Bool {
        loginItemStatus == .requiresApproval
    }

    var launchAtLoginStatusDescription: String {
        switch loginItemStatus {
        case .enabled:
            return "Enabled"
        case .notRegistered:
            return "Not registered"
        case .requiresApproval:
            return "Requires approval in System Settings"
        case .notFound:
            return "Login item not found"
        @unknown default:
            return "Unknown"
        }
    }

    func refreshLoginItemStatus() {
        loginItemStatus = SMAppService.mainApp.status
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastLoginItemError = nil
        } catch {
            lastLoginItemError = String(describing: error)
        }

        refreshLoginItemStatus()
    }

    func setEdge(_ edge: ShelfEdge, enabled: Bool) {
        var edges = settings.enabledEdges

        if enabled {
            if !edges.contains(edge) {
                edges.append(edge)
            }
        } else {
            edges.removeAll { $0 == edge }
            if edges.isEmpty {
                edges = [.right]
            }
        }

        settings.enabledEdges = edges
    }

    func setHotZoneThickness(_ thickness: CGFloat) {
        settings.hotZoneThickness = thickness
    }

    func setRevealDelay(_ delay: TimeInterval) {
        settings.revealDelay = delay
    }

    func setShowDockIcon(_ showDockIcon: Bool) {
        settings.showDockIcon = showDockIcon
    }

    func setRemoveItemsAfterAcceptedDragOut(_ remove: Bool) {
        settings.removeItemsAfterAcceptedDragOut = remove
    }

    func openLoginItemsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func clearShelf() {
        onClearShelf?()
    }

    private func persist() {
        try? store.save(settings)
    }
}

final class SettingsWindowController {
    private let window: NSWindow

    init(viewModel: SettingsViewModel) {
        let hostingController = NSHostingController(rootView: SettingsView(viewModel: viewModel))
        self.window = NSWindow(contentViewController: hostingController)
        self.window.title = "Shelflet Settings"
        self.window.styleMask = [.titled, .closable, .miniaturizable]
        self.window.setContentSize(NSSize(width: 460, height: 430))
        self.window.isReleasedWhenClosed = false
        self.window.center()
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Show Dock icon",
                    isOn: Binding(
                        get: { viewModel.settings.showDockIcon },
                        set: { viewModel.setShowDockIcon($0) }
                    )
                )

                Toggle(
                    "Remove items after accepted drag-out",
                    isOn: Binding(
                        get: { viewModel.settings.removeItemsAfterAcceptedDragOut },
                        set: { viewModel.setRemoveItemsAfterAcceptedDragOut($0) }
                    )
                )
            }

            Section("Launch") {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: { viewModel.setLaunchAtLogin($0) }
                    )
                )

                Text(viewModel.launchAtLoginStatusDescription)
                    .foregroundStyle(viewModel.launchAtLoginRequiresApproval ? .orange : .secondary)

                if let error = viewModel.lastLoginItemError {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if viewModel.launchAtLoginRequiresApproval {
                    Button("Open Login Items Settings") {
                        viewModel.openLoginItemsSettings()
                    }
                }
            }

            Section("Edges") {
                ForEach(ShelfEdge.allCases, id: \.self) { edge in
                    Toggle(
                        edge.rawValue.capitalized,
                        isOn: Binding(
                            get: { viewModel.settings.enabledEdges.contains(edge) },
                            set: { viewModel.setEdge(edge, enabled: $0) }
                        )
                    )
                }
            }

            Section("Hot Zone") {
                HStack {
                    Text("Thickness")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.settings.hotZoneThickness) },
                            set: { viewModel.setHotZoneThickness(CGFloat($0)) }
                        ),
                        in: 2...32,
                        step: 1
                    )
                    Text("\(Int(viewModel.settings.hotZoneThickness)) px")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }

                HStack {
                    Text("Reveal delay")
                    Slider(
                        value: Binding(
                            get: { viewModel.settings.revealDelay },
                            set: { viewModel.setRevealDelay($0) }
                        ),
                        in: 0...0.6,
                        step: 0.03
                    )
                    Text("\(viewModel.settings.revealDelay, specifier: "%.2f") s")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }

            Section("Shelf") {
                Button("Clear Shelf", role: .destructive) {
                    viewModel.clearShelf()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 440, minHeight: 400)
        .onAppear {
            viewModel.refreshLoginItemStatus()
        }
    }
}
