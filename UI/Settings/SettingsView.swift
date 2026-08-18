import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "switch.2") }
            AccountsSettingsView()
                .tabItem { Label("Accounts", systemImage: "person.2") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintpalette") }
            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .padding(18)
        .frame(width: 680, height: 490)
    }
}

