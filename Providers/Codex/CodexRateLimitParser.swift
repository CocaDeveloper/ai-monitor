import Foundation

public enum CodexRateLimitParser {
    public static func snapshot(from result: CodexRateLimitsResult, accountID: UUID, now: Date = .now) throws -> UsageSnapshot {
        let limits: [(String, CodexRateLimit)]
        if let byID = result.rateLimitsByLimitId, !byID.isEmpty {
            limits = byID.sorted { $0.key < $1.key }
        } else if let single = result.rateLimits {
            limits = [(single.limitId ?? "codex", single)]
        } else {
            throw ProviderError.noUsageData
        }

        let metrics = limits.map { key, limit in
            let windows = [
                makeWindow(limit.primary, id: "\(key)-primary", label: "Primary window", isPrimary: true),
                makeWindow(limit.secondary, id: "\(key)-secondary", label: "Secondary window", isPrimary: false),
            ].compactMap { $0 }
            let remaining = windows.first(where: \ResetWindow.isPrimary)?.remainingPercent
            let credits = limit.credits?.balance.map { CreditBalance(remaining: $0) }
            return UsageMetric(
                id: key,
                label: limit.limitName ?? (key == "codex" ? "Codex" : key),
                kind: remaining != nil ? .percentage : (credits != nil ? .credits : .unavailable),
                remainingPercent: remaining,
                credits: credits,
                windows: windows
            )
        }
        guard metrics.contains(where: { $0.kind != .unavailable }) else { throw ProviderError.noUsageData }
        return UsageSnapshot(accountID: accountID, providerID: .codex, metrics: metrics, updatedAt: now)
    }

    private static func makeWindow(_ source: CodexRateWindow?, id: String, label: String, isPrimary: Bool) -> ResetWindow? {
        guard let source else { return nil }
        return ResetWindow(
            id: id,
            label: label,
            usedPercent: source.usedPercent,
            resetsAt: source.resetsAt.map(Date.init(timeIntervalSince1970:)),
            durationMinutes: source.windowDurationMins,
            isPrimary: isPrimary
        )
    }
}

