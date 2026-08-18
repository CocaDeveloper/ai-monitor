import Foundation

public struct SharedAccountSnapshot: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var providerID: ProviderID
    public var summary: String
    public var resetSummary: String?
    public var status: ConnectionStatus

    public init(id: UUID, name: String, providerID: ProviderID, summary: String, resetSummary: String?, status: ConnectionStatus) {
        self.id = id
        self.name = name
        self.providerID = providerID
        self.summary = summary
        self.resetSummary = resetSummary
        self.status = status
    }
}

public struct SharedWidgetSnapshot: Codable, Hashable, Sendable {
    public var accounts: [SharedAccountSnapshot]
    public var updatedAt: Date?

    public init(accounts: [SharedAccountSnapshot] = [], updatedAt: Date? = nil) {
        self.accounts = accounts
        self.updatedAt = updatedAt
    }

    public static func make(accounts: [ProviderAccount], snapshots: [UUID: UsageSnapshot], now: Date = .now) -> Self {
        let rows = accounts.sorted { $0.sortOrder < $1.sortOrder }.compactMap { account -> SharedAccountSnapshot? in
            guard let snapshot = snapshots[account.id] else {
                return SharedAccountSnapshot(
                    id: account.id,
                    name: account.displayName,
                    providerID: account.providerID,
                    summary: account.status == .notConnected ? String(localized: "Login required") : String(localized: "Usage unavailable"),
                    resetSummary: nil,
                    status: account.status
                )
            }
            guard let metric = snapshot.primaryMetric else {
                return SharedAccountSnapshot(id: account.id, name: account.displayName, providerID: account.providerID, summary: String(localized: "Usage unavailable"), resetSummary: nil, status: snapshot.connectionStatus)
            }
            let summary: String
            if let percent = metric.remainingPercent {
                summary = UsageFormatters.percent(percent)
            } else if let credits = metric.credits {
                summary = UsageFormatters.credits(credits)
            } else if let used = metric.used, let limit = metric.limit {
                summary = "\(Int(used))/\(Int(limit)) \(metric.unit ?? "")"
            } else {
                summary = String(localized: "Usage unavailable")
            }
            let reset = metric.windows.first(where: \ResetWindow.isPrimary)?.resetsAt
            return SharedAccountSnapshot(
                id: account.id,
                name: account.displayName,
                providerID: account.providerID,
                summary: summary,
                resetSummary: reset.map { UsageFormatters.reset($0, relativeTo: now) },
                status: snapshot.connectionStatus
            )
        }
        return .init(accounts: rows, updatedAt: snapshots.values.map(\.updatedAt).max())
    }
}
