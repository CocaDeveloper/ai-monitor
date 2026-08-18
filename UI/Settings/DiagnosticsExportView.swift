import AppKit
import SwiftUI

struct DiagnosticsExportView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Diagnostics").font(.title2.bold())
            Text("The file will include exactly:").font(.headline)
            ForEach(DiagnosticExporter.disclosedFields, id: \.self) { field in
                Label(field, systemImage: "checkmark.circle.fill")
            }
            Text("It will not include passwords, tokens, API keys, cookies, account IDs, full email addresses, auth.json, private keys, MCP secrets, or URLs containing credentials.")
                .font(.callout).foregroundStyle(.secondary)
            if let message { Text(message).font(.callout).foregroundStyle(.red) }
            Spacer()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Choose Save Location…") { export() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 560, height: 430)
    }

    private func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AI-Monitor-Diagnostics.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try DiagnosticExporter.encode(environment.diagnosticReport()).write(to: url, options: .atomic)
            dismiss()
        } catch { message = "Could not save the diagnostics file." }
    }
}

