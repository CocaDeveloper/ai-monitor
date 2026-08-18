import SwiftUI

@main
struct AIMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(environment)
        } label: {
            MenuBarIconView()
                .accessibilityLabel("AI Monitor")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(environment)
        }
    }
}

