import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: theme) {
                    Text("Retro Beige").tag(AppPreferences.Theme.retroBeige)
                    Text("Dark CRT").tag(AppPreferences.Theme.darkCRT)
                    Text("System").tag(AppPreferences.Theme.system)
                }
                .pickerStyle(.radioGroup)
            }
            Section("Display") {
                Toggle("Progress bars", isOn: bool(\.showProgressBars))
                Toggle("Compact mode", isOn: bool(\.compactMode))
            }
            Section("Preview") {
                HStack {
                    RoundedRectangle(cornerRadius: 8).fill(DesignTokens.beige).frame(width: 110, height: 70)
                        .overlay(RoundedRectangle(cornerRadius: 5).fill(DesignTokens.screen).padding(9))
                    VStack(alignment: .leading) {
                        Text("AI MONITOR").pixelText(size: 13, weight: .bold)
                        Text("Retro, readable, and original.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var theme: Binding<AppPreferences.Theme> {
        Binding(get: { environment.preferences.theme }, set: { value in environment.updatePreferences { $0.theme = value } })
    }

    private func bool(_ keyPath: WritableKeyPath<AppPreferences, Bool>) -> Binding<Bool> {
        Binding(get: { environment.preferences[keyPath: keyPath] }, set: { value in environment.updatePreferences { $0[keyPath: keyPath] = value } })
    }
}

