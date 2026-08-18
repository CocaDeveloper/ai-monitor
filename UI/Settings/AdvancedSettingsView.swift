import AppKit
import SwiftUI

struct AdvancedSettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var codexPath = ""
    @State private var showDiagnostics = false
    @State private var showMCP = false
    @State private var detectedCodex = "Checking…"

    var body: some View {
        Form {
            Section("Codex CLI") {
                TextField("Custom path (optional)", text: $codexPath)
                    .onAppear { codexPath = environment.preferences.customCodexPath ?? "" }
                HStack {
                    Text(detectedCodex)
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    Spacer()
                    Button("Save Path") {
                        environment.updatePreferences { $0.customCodexPath = codexPath.isEmpty ? nil : codexPath }
                        Task { await detectCodex() }
                    }
                    Button("Check Again") { Task { await detectCodex() } }
                }
                Text("App Server status: started only during sign-in and refresh.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Custom MCP") {
                Toggle("Show experimental Custom MCP setup", isOn: $showMCP)
                if showMCP {
                    Text("Only connect a server you trust. AI Monitor shows the endpoint before connecting, stores bearer credentials in Keychain, and automatically calls only read-only usage tools.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Custom MCP connection editing is an advanced beta and is not enabled in this release.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            Section("Support") {
                Button("Export Diagnostics") { showDiagnostics = true }
                Button("Clear cached snapshots") {
                    // Keep account credentials and provider-managed authentication untouched.
                    for account in environment.accounts { environment.removeCachedSnapshot(accountID: account.id) }
                }
                Button("Reset onboarding") { hasCompletedOnboarding = false }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showDiagnostics) { DiagnosticsExportView() }
        .task { await detectCodex() }
    }

    private func detectCodex() async {
        let manager = CodexProcessManager(manuallyConfiguredPath: codexPath.isEmpty ? nil : codexPath)
        guard let path = manager.executableURL()?.path else {
            detectedCodex = String(localized: "Codex CLI not found")
            return
        }
        let version = await manager.versionString() ?? String(localized: "version unavailable")
        detectedCodex = String(format: String(localized: "Detected: %@ · %@"), path, version)
    }
}
