import SwiftUI

struct AddAccountView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var selected: ProviderID?
    @State private var accountName = "Personal"
    @State private var isConnecting = false
    @State private var connectionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(selected == .codex ? "Connect Codex" : "Add Account").font(.title2.bold())
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(isConnecting)
            }

            if selected == .codex {
                TextField("Account name", text: $accountName)
                    .textFieldStyle(.roundedBorder)
                Text("AI Monitor opens the official ChatGPT sign-in page. Your password is never shown to or stored by AI Monitor.")
                    .font(.callout).foregroundStyle(.secondary)
                if let connectionError {
                    Text(connectionError)
                        .font(.callout)
                        .foregroundStyle(DesignTokens.danger)
                }
                Button {
                    Task { await authenticate() }
                } label: {
                    HStack(spacing: 8) {
                        if isConnecting { ProgressView().controlSize(.small) }
                        Text(isConnecting ? "Waiting for sign-in…" : "Sign in with ChatGPT")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isConnecting)
            } else {
                providerButton(
                    id: .codex,
                    title: "Codex / OpenAI",
                    subtitle: "Monitor your Codex limits and reset times.",
                    status: "Available"
                )
                providerButton(
                    id: .kling,
                    title: "Kling",
                    subtitle: "Credit balance is shown only when an official read-only interface is available.",
                    status: "Beta"
                )
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("More providers").font(.headline)
                        Text("Coming later.").font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Planned").font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 430, height: 330)
    }

    private func authenticate() async {
        isConnecting = true
        connectionError = nil
        let trimmed = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "Codex Personal" : "Codex \(trimmed)"
        do {
            try await environment.authenticateAndAddCodex(name: displayName)
            dismiss()
        } catch ProviderError.loginCancelled {
            connectionError = String(localized: "Sign-in was cancelled. No account was added.")
        } catch {
            connectionError = error.localizedDescription
        }
        isConnecting = false
    }

    private func providerButton(id: ProviderID, title: String, subtitle: String, status: String) -> some View {
        Button {
            if id == .kling {
                environment.addAccount(providerID: .kling, name: "Kling")
                dismiss()
            } else { selected = id }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer()
                Text(status).font(.caption.bold()).foregroundStyle(id == .codex ? .green : .orange)
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
