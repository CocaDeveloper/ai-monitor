import AppKit
import SwiftUI

struct CheckUpdatesView: View {
    @State private var status: String?
    @State private var release: AvailableRelease?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button("Check for Updates") { Task { await check() } }
                if let release {
                    Button("View Release") { NSWorkspace.shared.open(release.htmlURL) }
                    if let dmg = release.dmgURL { Button("Download Update") { NSWorkspace.shared.open(dmg) } }
                }
            }
            if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func check() async {
        let owner = Bundle.main.object(forInfoDictionaryKey: "AIMonitorGitHubOwner") as? String ?? "OWNER"
        let repo = Bundle.main.object(forInfoDictionaryKey: "AIMonitorGitHubRepo") as? String ?? "ai-monitor"
        do {
            let latest = try await UpdateChecker(owner: owner, repository: repo).latestStableRelease()
            let currentText = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
            if let current = SemanticVersion(currentText), let next = SemanticVersion(latest.tagName), current < next {
                release = latest
                status = "AI Monitor \(latest.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))) is available."
            } else {
                release = nil
                status = "You are using the latest stable version."
            }
        } catch { status = error.localizedDescription }
    }
}

