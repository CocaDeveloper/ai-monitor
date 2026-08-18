import SwiftUI

@main
struct AIMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(presentation: .menuBar)
                .environmentObject(environment)
        } label: {
            MainWindowLauncher(appDelegate: appDelegate)
                .environmentObject(environment)
                .accessibilityLabel("AI Monitor")
        }
        .menuBarExtraStyle(.window)

        Window("AI Monitor", id: "main") {
            MenuBarContentView(presentation: .window)
                .environmentObject(environment)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(environment)
        }
    }
}

private struct MainWindowLauncher: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var environment: AppEnvironment
    let appDelegate: AppDelegate
    @State private var hasOpenedWindow = false

    var body: some View {
        MenuBarIconView()
            .onAppear {
                appDelegate.openMainWindow = { openWindow(id: "main") }
            }
            .task(id: environment.hasLoadedState && environment.preferences.showDockIcon) {
                guard environment.hasLoadedState,
                      environment.preferences.showDockIcon,
                      !hasOpenedWindow else { return }
                hasOpenedWindow = true
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
