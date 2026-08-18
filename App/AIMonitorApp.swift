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
            MainWindowLauncher()
                .accessibilityLabel("AI Monitor")
        }
        .menuBarExtraStyle(.window)

        Window("AI Monitor", id: "main") {
            MenuBarContentView()
                .environmentObject(environment)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(environment)
        }
    }
}

private struct MainWindowLauncher: View {
    @Environment(\.openWindow) private var openWindow
    @State private var hasOpenedWindow = false

    var body: some View {
        MenuBarIconView()
            .task {
                guard !hasOpenedWindow else { return }
                hasOpenedWindow = true
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
