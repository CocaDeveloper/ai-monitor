import SwiftUI

struct MenuBarContentView: View {
    enum Presentation {
        case menuBar
        case window
    }

    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openSettings) private var openSettings
    @Environment(\.dismissWindow) private var dismissWindow
    private let onboardingOverride: Bool?
    private let presentation: Presentation

    init(showOnboarding: Bool? = nil, presentation: Presentation = .menuBar) {
        self.onboardingOverride = showOnboarding
        self.presentation = presentation
    }

    var body: some View {
        Group {
            if onboardingOverride ?? !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                monitor
            }
        }
        .frame(width: 360, height: preferredHeight)
        .background(Color.clear)
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
                        Label("Add", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button { openSettings() } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Spacer()
                    Button {
                        if presentation == .window {
                            dismissWindow(id: "main")
                        } else {
                            NSApp.terminate(nil)
                        }
                    } label: {
                        Image(systemName: presentation == .window ? "menubar.rectangle" : "power")
                    }
                    .help(presentation == .window ? "Hide in menu bar" : "Quit AI Monitor")
                    .accessibilityLabel(presentation == .window ? "Hide in menu bar" : "Quit AI Monitor")
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

    private var preferredHeight: CGFloat {
        if onboardingOverride ?? !hasCompletedOnboarding { return 430 }
        let visibleRows = min(max(environment.accounts.count, 1), 3)
        let contentHeight = 250 + CGFloat(visibleRows * (environment.preferences.compactMode ? 62 : 78))
        return min(environment.preferences.compactMode ? 360 : 430, max(318, contentHeight))
    }
}
