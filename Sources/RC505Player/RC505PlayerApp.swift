import SwiftUI
import AppKit

@main
struct RC505PlayerApp: App {
    // Swift Package executables aren't launched from a real .app bundle, so
    // without this the process can start without ever becoming the
    // foreground app (no Dock icon, window never raised).
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("RC-505 Player") {
            ContentView()
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
    }
}
