import SwiftUI

private enum PreviewFixtures {
    static func state(remaining: Double = 82, status: ConnectionStatus = .connected, name: String = "Codex Personal") -> PersistedState {
        let account = ProviderAccount(id: UUID(), providerID: .codex, displayName: name, planName: "Plus", status: status)
        let window = ResetWindow(id: "primary", label: "5 hour limit", usedPercent: 100 - remaining, resetsAt: .now.addingTimeInterval(7_200), durationMinutes: 300, isPrimary: true)
        let metric = UsageMetric(id: "codex", label: "Codex", kind: .percentage, remainingPercent: remaining, windows: [window])
        let snapshot = UsageSnapshot(accountID: account.id, providerID: .codex, metrics: [metric], connectionStatus: status)
        return PersistedState(accounts: [account], snapshots: [account.id: snapshot])
    }

    static var multiple: PersistedState {
        let first = state(remaining: 82, name: "Codex Personal")
        let secondAccount = ProviderAccount(providerID: .codex, displayName: "Codex Work", planName: "Team", sortOrder: 1, status: .connected)
        let window = ResetWindow(id: "secondary", label: "Weekly limit", usedPercent: 62, resetsAt: .now.addingTimeInterval(86_400), durationMinutes: 10_080, isPrimary: true)
        let metric = UsageMetric(id: "work", label: "Codex", kind: .percentage, remainingPercent: 38, windows: [window])
        let snapshot = UsageSnapshot(accountID: secondAccount.id, providerID: .codex, metrics: [metric])
        return PersistedState(accounts: first.accounts + [secondAccount], snapshots: first.snapshots.merging([secondAccount.id: snapshot]) { _, new in new })
    }

    static var klingCredits: (ProviderAccount, UsageSnapshot) {
        let account = ProviderAccount(providerID: .kling, displayName: "Kling Preview", status: .connected)
        let metric = UsageMetric(id: "credits", label: "Credits", kind: .credits, credits: .init(remaining: 540))
        return (account, UsageSnapshot(accountID: account.id, providerID: .kling, metrics: [metric]))
    }

    static func themed(_ theme: AppPreferences.Theme) -> PersistedState {
        var value = state()
        value.preferences.theme = theme
        return value
    }
}

#Preview("Popup — no account") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: .init()))
}

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false)).environmentObject(AppEnvironment(previewState: .init())).frame(width: 410, height: 500)
}

#Preview("Codex — connected 82%") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.state(remaining: 82)))
}

#Preview("Codex — 38%") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.state(remaining: 38)))
}

#Preview("Codex — 17%") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.state(remaining: 17)))
}

#Preview("Multiple accounts") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.multiple))
}

#Preview("Kling — credits design") {
    let pair = PreviewFixtures.klingCredits
    AccountUsageRow(account: pair.0, snapshot: pair.1, showProgress: true, onRefresh: {}, onConnect: {}).padding().background(DesignTokens.screen)
}

#Preview("Kling — connected, balance unavailable") {
    AccountUsageRow(account: .init(providerID: .kling, displayName: "Kling", status: .unavailable), snapshot: nil, showProgress: true, onRefresh: {}, onConnect: {}).padding().background(DesignTokens.screen)
}

#Preview("Offline") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.state(remaining: 82, status: .offline)))
}

#Preview("Loading") {
    AccountUsageRow(account: .init(providerID: .codex, displayName: "Codex", status: .refreshing), snapshot: nil, showProgress: true, onRefresh: {}, onConnect: {}).padding().background(DesignTokens.screen)
}

#Preview("Login required") {
    AccountUsageRow(account: .init(providerID: .codex, displayName: "Codex", status: .notConnected), snapshot: nil, showProgress: true, onRefresh: {}, onConnect: {}).padding().background(DesignTokens.screen)
}

#Preview("Theme — Retro Beige") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.themed(.retroBeige)))
}

#Preview("Theme — Dark CRT") {
    MenuBarContentView(showOnboarding: false).environmentObject(AppEnvironment(previewState: PreviewFixtures.themed(.darkCRT)))
}
