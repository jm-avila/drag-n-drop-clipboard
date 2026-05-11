import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var composition: AppComposition?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        let composition = AppComposition()
        self.composition = composition
        composition.start()
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        composition?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
