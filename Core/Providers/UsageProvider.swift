import Foundation

public protocol UsageProvider: Sendable {
    var id: ProviderID { get }
    var displayName: String { get }
    var capabilities: Set<ProviderCapability> { get }

    func connect(account: ProviderAccount) async throws
    func disconnect(account: ProviderAccount) async throws
    func refresh(account: ProviderAccount) async throws -> UsageSnapshot
}

