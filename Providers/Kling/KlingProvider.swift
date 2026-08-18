import Foundation

public struct KlingProvider: UsageProvider {
    public let id: ProviderID = .kling
    public let displayName = "Kling"
    public let capabilities: Set<ProviderCapability> = [.credits]

    public init() {}

    public func connect(account: ProviderAccount) async throws {
        throw ProviderError.transport("Kling does not currently document a read-only balance login for third-party desktop apps")
    }

    public func disconnect(account: ProviderAccount) async throws {}

    public func refresh(account: ProviderAccount) async throws -> UsageSnapshot {
        let metric = UsageMetric(id: "kling-credits", label: "Kling", kind: .unavailable)
        return UsageSnapshot(
            accountID: account.id,
            providerID: .kling,
            metrics: [metric],
            connectionStatus: .unavailable
        )
    }
}

