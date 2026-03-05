import SwiftUI
import AppKit
import VTubeLinkShared

class AppDelegate: NSObject, NSApplicationDelegate {
    // Quit the app process when the window is closed, but do NOT kill the service
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
