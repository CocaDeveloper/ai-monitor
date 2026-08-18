import Foundation

public struct CodexProvider: UsageProvider {
    public let id: ProviderID = .codex
    public let displayName = "Codex / OpenAI"
    public let capabilities: Set<ProviderCapability> = [
        .percentage, .credits, .resetWindows, .multipleLimits, .accountDetails, .notifications, .browserLogin,
    ]

    private let processManager: CodexProcessManager
    private let store: AccountStore
    private let authentication = CodexAuthenticationManager()

    public init(processManager: CodexProcessManager = .init(), store: AccountStore = .init()) {
        self.processManager = processManager
        self.store = store
    }

    public func connect(account: ProviderAccount) async throws {
        let client = try await makeClient(account: account)
        do {
            try await client.start(version: Self.appVersion)
            try await authentication.login(using: client)
            await client.stop()
        } catch {
            await client.stop()
            throw error
        }
    }

    public func disconnect(account: ProviderAccount) async throws {
        let client = try await makeClient(account: account)
        do {
            try await client.start(version: Self.appVersion)
            let _: EmptyResult = try await client.request(.accountLogout, params: EmptyParams())
            await client.stop()
        } catch {
            await client.stop()
            throw error
        }
    }

    public func refresh(account: ProviderAccount) async throws -> UsageSnapshot {
        let client = try await makeClient(account: account)
        do {
            try await client.start(version: Self.appVersion)
            let accountResult: CodexAccountReadResult = try await client.request(.accountRead, params: CodexAccountReadParams())
            guard accountResult.account?.type == "chatgpt" else { throw ProviderError.notConnected }
            let limits: CodexRateLimitsResult = try await client.request(.accountRateLimitsRead, params: EmptyParams())
            let snapshot = try CodexRateLimitParser.snapshot(from: limits, accountID: account.id)
            await client.stop()
            return snapshot
        } catch {
            await client.stop()
            throw error
        }
    }

    public func accountDetails(account: ProviderAccount) async throws -> CodexAccountReadResult.Account? {
        let client = try await makeClient(account: account)
        do {
            try await client.start(version: Self.appVersion)
            let result: CodexAccountReadResult = try await client.request(.accountRead, params: CodexAccountReadParams())
            await client.stop()
            return result.account
        } catch {
            await client.stop()
            throw error
        }
    }

    private func makeClient(account: ProviderAccount) async throws -> CodexAppServerClient {
        guard let executable = processManager.executableURL() else { throw ProviderError.executableNotFound }
        let home = try await store.codexHome(for: account.id)
        try processManager.prepareHome(home)
        return CodexAppServerClient(executableURL: executable, codexHome: home, timeout: 30)
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}

