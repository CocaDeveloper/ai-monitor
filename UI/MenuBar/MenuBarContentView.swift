import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openSettings) private var openSettings
    private let onboardingOverride: Bool?

    init(showOnboarding: Bool? = nil) {
        self.onboardingOverride = showOnboarding
    }

    var body: some View {
        Group {
            if onboardingOverride ?? !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                monitor
            }
        }
        .frame(width: 410, height: (onboardingOverride ?? !hasCompletedOnboarding) ? 500 : environment.preferences.compactMode ? 440 : 510)
        .sheet(isPresented: $environment.addAccountPresented) { AddAccountView() }
        .alert("AI Monitor", isPresented: Binding(
            get: { environment.presentedError != nil },
            set: { if !$0 { environment.presentedError = nil } }
        )) {
            Button("OK", role: .cancel) { environment.presentedError = nil }
        } message: {
            Text(environment.presentedError ?? "")
        }
    }

    private var monitor: some View {
        CRTFrame {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI MONITOR").pixelText(size: 15, weight: .bold).foregroundStyle(.white)
                        Text(latestUpdate).pixelText(size: 10).foregroundStyle(DesignTokens.muted)
                    }
                    Spacer()
                    Button { Task { await environment.refreshAll(force: true) } } label: {
                        Image(systemName: environment.isRefreshing ? "hourglass" : "arrow.clockwise")
                            .foregroundStyle(DesignTokens.phosphorGreen)
                    }
                    .buttonStyle(.plain)
                    .disabled(environment.isRefreshing)
                    .keyboardShortcut("r", modifiers: .command)
                    .accessibilityLabel("Refresh all accounts")
                }
                .padding(.bottom, 10)

                Divider().overlay(DesignTokens.border)

                if environment.accounts.isEmpty {
                    EmptyAccountsView { environment.addAccountPresented = true }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(environment.accounts) { account in
                                AccountUsageRow(
                                    account: account,
                                    snapshot: environment.snapshot(for: account.id),
                                    showProgress: environment.preferences.showProgressBars,
                                    onRefresh: { Task { await environment.refresh(accountID: account.id, force: true) } },
                                    onConnect: { Task { await environment.connect(accountID: account.id) } }
                                )
                                if account.id != environment.accounts.last?.id {
                                    Divider().overlay(Color.white.opacity(0.10))
                                }
                            }
                        }
                    }
                }

                Divider().overlay(DesignTokens.border)
                HStack(spacing: 8) {
                    Button { environment.addAccountPresented = true } label: {
                        Label("Add Account", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button { openSettings() } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Spacer()
                    Button { NSApp.terminate(nil) } label: {
                        Image(systemName: "power")
                    }
                    .help("Quit AI Monitor")
                    .accessibilityLabel("Quit AI Monitor")
                }
                .buttonStyle(RetroButtonStyle())
                .padding(.top, 10)
            }
        }
        .background(Color.clear)
        .task { await environment.refreshAll() }
    }

    private var latestUpdate: String {
        let date = environment.state.snapshots.values.map(\.updatedAt).max()
        return environment.isRefreshing ? String(localized: "Refreshing…") : UsageFormatters.updated(date)
    }
}
