import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var launchAtLogin = LaunchAtLoginController()

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: launchAtLogin.setEnabled
                ))
                if let message = launchAtLogin.message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            Section("Refresh") {
                Picker("Refresh interval", selection: preference(\.refreshIntervalMinutes)) {
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                }
                Toggle("Show reset countdown", isOn: preference(\.showResetCountdown))
                Toggle("Show menu bar warning indicator", isOn: preference(\.showWarningIndicator))
            }
            Section("Updates") {
                Toggle("Check for updates", isOn: preference(\.checkForUpdates))
                CheckUpdatesView()
            }
            Section("About") {
                HStack {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 42, height: 42)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Monitor").font(.headline)
                        Text("Version \(version) (\(build))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text("MIT licensed · No analytics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func preference<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { environment.preferences[keyPath: keyPath] },
            set: { value in environment.updatePreferences { $0[keyPath: keyPath] = value } }
        )
    }

    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development" }
    private var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }
}
