import SwiftUI
import AppKit

@main
struct MontyWorkoutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(history)
                .frame(minWidth: 880, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1060, height: 740)
    }
}

/// Makes the executable behave like a normal windowed app (Dock icon, focus)
/// even when launched via `swift run` without a bundle.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
