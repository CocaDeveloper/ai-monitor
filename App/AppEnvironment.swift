import AppKit
import Foundation
import WidgetKit

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var state = PersistedState()
    @Published private(set) var hasLoadedState = false
    @Published var presentedError: String?
    @Published var isRefreshing = false
    @Published var addAccountPresented = false
    @Published var diagnosticsPresented = false

    let store: AccountStore
    let sharedStore: SharedSnapshotStore
    private var lastAttempts: [UUID: Date] = [:]
    private var failureCounts: [UUID: Int] = [:]
    private let refreshPolicy = RefreshPolicy()
    private let isUITesting: Bool

    init(store: AccountStore = .init(), sharedStore: SharedSnapshotStore = .init()) {
        self.store = store
        self.sharedStore = sharedStore
        #if DEBUG
        let scenario = ProcessInfo.processInfo.environment["AIMONITOR_UI_SCENARIO"]
        #else
        let scenario: String? = nil
        #endif
        self.isUITesting = scenario != nil
        if let scenario {
            state = Self.uiTestState(scenario)
            hasLoadedState = true
            if scenario == "error" { presentedError = "Connection failed in test preview." }
        } else {
            Task { await load() }
        }
    }

    init(previewState: PersistedState) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("AI-Monitor-Previews", isDirectory: true)
        self.store = AccountStore(directory: directory)
        self.sharedStore = SharedSnapshotStore(directory: directory)
        self.isUITesting = true
        self.state = previewState
        self.hasLoadedState = true
    }

    var accounts: [ProviderAccount] { state.accounts.sorted { $0.sortOrder < $1.sortOrder } }
    var preferences: AppPreferences { state.preferences }

    func load() async {
        defer {
            hasLoadedState = true
            applyDockVisibility()
        }
        do { state = try await store.load() }
        catch { presentedError = String(localized: "Could not load your saved accounts. No data was deleted.") }
    }

    func updatePreferences(_ mutate: (inout AppPreferences) -> Void) {
        let showedDockIcon = state.preferences.showDockIcon
        mutate(&state.preferences)
        if state.preferences.showDockIcon != showedDockIcon { applyDockVisibility() }
        persist()
    }

    func authenticateAndAddCodex(name: String) async throws {
        let account = ProviderAccount(
            providerID: .codex,
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Codex Personal" : name,
            sortOrder: state.accounts.count,
            status: .waitingForLogin
        )
        do {
            try await provider(for: account).connect(account: account)
            var authenticated = account
            authenticated.status = .connected
            if let details = try? await codexProvider().accountDetails(account: account) {
                authenticated.emailHint = details.email.map(Self.maskEmail)
                authenticated.planName = details.planType
            }
            state.accounts.append(authenticated)
            persist()
            await refresh(accountID: authenticated.id, force: true)
        } catch {
            try? await store.removeCodexHome(for: account.id)
            throw error
        }
    }

    func addAccount(providerID: ProviderID, name: String) {
        guard providerID != .codex else {
            presentedError = String(localized: "Sign in before adding this account.")
            return
        }
        let account = ProviderAccount(
            providerID: providerID,
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultName(for: providerID) : name,
            sortOrder: state.accounts.count,
            status: providerID == .kling ? .unavailable : .notConnected
        )
        state.accounts.append(account)
        persist()
    }

    func connect(accountID: UUID) async {
        guard let account = state.accounts.first(where: { $0.id == accountID }) else { return }
        if account.providerID == .kling {
            presentedError = String(localized: "Kling’s public documentation does not currently provide a verified read-only credit balance login for this app. The account remains marked Usage unavailable.")
            return
        }
        setStatus(.openingBrowser, accountID: accountID)
        let provider = provider(for: account)
        do {
            setStatus(.waitingForLogin, accountID: accountID)
            try await provider.connect(account: account)
            setStatus(.connected, accountID: accountID)
            if account.providerID == .codex {
                let codex = codexProvider()
                if let details = try? await codex.accountDetails(account: account) {
                    updateAccount(accountID) {
                        $0.emailHint = details.email.map(Self.maskEmail)
                        $0.planName = details.planType
                    }
                }
            }
            await refresh(accountID: accountID, force: true)
        } catch ProviderError.loginCancelled {
            setStatus(.loginCancelled, accountID: accountID)
        } catch {
            setStatus(.loginFailed, accountID: accountID)
            presentedError = error.localizedDescription
        }
    }

    func disconnect(accountID: UUID) async {
        guard let account = state.accounts.first(where: { $0.id == accountID }) else { return }
        do {
            try await provider(for: account).disconnect(account: account)
            setStatus(.notConnected, accountID: accountID)
        } catch { presentedError = error.localizedDescription }
    }

    func refreshAll(force: Bool = false) async {
        if isUITesting { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        for account in accounts { await refresh(accountID: account.id, force: force) }
    }

    func refresh(accountID: UUID, force: Bool = false) async {
        guard let account = state.accounts.first(where: { $0.id == accountID }) else { return }
        let now = Date()
        if !force, !refreshPolicy.canRefresh(lastAttempt: lastAttempts[accountID], now: now) { return }
        if !force, let attempt = lastAttempts[accountID] {
            let wait = refreshPolicy.backoff(afterFailureCount: failureCounts[accountID, default: 0])
            if now.timeIntervalSince(attempt) < wait { return }
        }
        lastAttempts[accountID] = now
        setStatus(.refreshing, accountID: accountID, persist: false)
        do {
            let snapshot = try await provider(for: account).refresh(account: account)
            state.snapshots[accountID] = snapshot
            failureCounts[accountID] = 0
            setStatus(snapshot.connectionStatus, accountID: accountID, persist: false)
            persist()
        } catch {
            failureCounts[accountID, default: 0] += 1
            setStatus(error is ProviderError && (error as? ProviderError) == .notConnected ? .notConnected : .offline, accountID: accountID, persist: false)
            // Deliberately preserve the last valid snapshot.
            presentedError = state.snapshots[accountID] == nil ? error.localizedDescription : String(localized: "Last update failed. Showing the previous value.")
            persist()
        }
    }

    func rename(accountID: UUID, name: String) {
        updateAccount(accountID) { $0.displayName = name }
    }

    func moveAccounts(fromOffsets: IndexSet, toOffset: Int) {
        var ordered = accounts
        ordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for index in ordered.indices { ordered[index].sortOrder = index }
        state.accounts = ordered
        persist()
    }

    func remove(accountID: UUID) {
        state.accounts.removeAll { $0.id == accountID }
        state.snapshots[accountID] = nil
        for index in state.accounts.indices { state.accounts[index].sortOrder = index }
        persist()
    }

    func removeCachedSnapshot(accountID: UUID) {
        state.snapshots[accountID] = nil
        persist()
    }

    func snapshot(for accountID: UUID) -> UsageSnapshot? { state.snapshots[accountID] }

    func diagnosticReport() -> DiagnosticReport {
        let codexPath = CodexProcessManager(manuallyConfiguredPath: state.preferences.customCodexPath).executableURL()
        let shared = try? sharedStore.load()
        return DiagnosticExporter.make(state: state, codexPath: codexPath, sharedSnapshot: shared)
    }

    private func provider(for account: ProviderAccount) -> any UsageProvider {
        switch account.providerID {
        case .codex: codexProvider()
        case .kling: KlingProvider()
        default: MockProvider(result: .failure(.noUsageData))
        }
    }

    private func codexProvider() -> CodexProvider {
        CodexProvider(
            processManager: .init(manuallyConfiguredPath: state.preferences.customCodexPath),
            store: store
        )
    }

    private func setStatus(_ status: ConnectionStatus, accountID: UUID, persist shouldPersist: Bool = true) {
        updateAccount(accountID, persist: shouldPersist) { $0.status = status }
    }

    private func updateAccount(_ accountID: UUID, persist shouldPersist: Bool = true, _ mutate: (inout ProviderAccount) -> Void) {
        guard let index = state.accounts.firstIndex(where: { $0.id == accountID }) else { return }
        mutate(&state.accounts[index])
        if shouldPersist { persist() }
    }

    private func persist() {
        let snapshot = SharedWidgetSnapshot.make(accounts: state.accounts, snapshots: state.snapshots)
        let stateToSave = state
        Task {
            do {
                try await store.save(stateToSave)
                try sharedStore.save(snapshot)
                WidgetCenter.shared.reloadAllTimelines()
            } catch { presentedError = String(localized: "Could not save changes. Your previous data remains on disk.") }
        }
    }

    private func applyDockVisibility() {
        NSApp.setActivationPolicy(state.preferences.showDockIcon ? .regular : .accessory)
    }

    private func defaultName(for providerID: ProviderID) -> String {
        providerID == .codex ? "Codex Personal" : providerID == .kling ? "Kling" : "AI Account"
    }

    private static func maskEmail(_ value: String) -> String {
        guard let at = value.firstIndex(of: "@"), let first = value.first else { return "Account connected" }
        return "\(first)•••\(value[at...])"
    }

    private static func uiTestState(_ scenario: String) -> PersistedState {
        guard scenario != "empty" else { return .init() }
        let account = ProviderAccount(
            id: UUID(uuidString: "B93D93B2-3B74-4E5B-8B66-34A6D8047D76")!,
            providerID: scenario == "mock" ? .mock : .codex,
            displayName: scenario == "mock" ? "Codex Preview" : "Codex Personal",
            planName: scenario == "mock" ? "Plus" : nil,
            status: scenario == "disconnected" ? .notConnected : scenario == "error" ? .loginFailed : .connected
        )
        guard scenario == "mock" else { return PersistedState(accounts: [account]) }
        let window = ResetWindow(id: "primary", label: "5 hour limit", usedPercent: 18, resetsAt: Date().addingTimeInterval(7_200), durationMinutes: 300, isPrimary: true)
        let metric = UsageMetric(id: "codex", label: "Codex", kind: .percentage, remainingPercent: 82, windows: [window])
        let snapshot = UsageSnapshot(accountID: account.id, providerID: .codex, metrics: [metric])
        return PersistedState(accounts: [account], snapshots: [account.id: snapshot])
    }
}
