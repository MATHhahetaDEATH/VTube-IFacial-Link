import SwiftUI
import AppKit

@main
struct MacApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
