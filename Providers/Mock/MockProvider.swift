import Foundation

public struct MockProvider: UsageProvider {
    public let id: ProviderID = .mock
    public let displayName = "Preview Provider"
    public let capabilities: Set<ProviderCapability> = [.percentage, .credits, .resetWindows, .multipleLimits]
    public var result: Result<UsageSnapshot, ProviderError>

    public init(result: Result<UsageSnapshot, ProviderError>) {
        self.result = result
    }

    public func connect(account: ProviderAccount) async throws {}
    public func disconnect(account: ProviderAccount) async throws {}

    public func refresh(account: ProviderAccount) async throws -> UsageSnapshot {
        try result.get()
    }

    public static func codex(accountID: UUID = UUID(), remaining: Double = 82) -> MockProvider {
        let reset = Calendar.current.date(byAdding: .hour, value: 2, to: .now)
        let window = ResetWindow(id: "codex-primary", label: "5 hour limit", usedPercent: 100 - remaining, resetsAt: reset, durationMinutes: 300, isPrimary: true)
        let metric = UsageMetric(id: "codex", label: "Codex", kind: .percentage, remainingPercent: remaining, windows: [window])
        return .init(result: .success(.init(accountID: accountID, providerID: .codex, metrics: [metric])))
    }
}

