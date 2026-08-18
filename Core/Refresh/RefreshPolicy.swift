import Foundation

public struct RefreshPolicy: Sendable {
    public var cooldown: TimeInterval
    public var baseBackoff: TimeInterval
    public var maximumBackoff: TimeInterval

    public init(cooldown: TimeInterval = 60, baseBackoff: TimeInterval = 30, maximumBackoff: TimeInterval = 30 * 60) {
        self.cooldown = cooldown
        self.baseBackoff = baseBackoff
        self.maximumBackoff = maximumBackoff
    }

    public func canRefresh(lastAttempt: Date?, now: Date = .now) -> Bool {
        guard let lastAttempt else { return true }
        return now.timeIntervalSince(lastAttempt) >= cooldown
    }

    public func backoff(afterFailureCount count: Int) -> TimeInterval {
        guard count > 0 else { return 0 }
        return min(maximumBackoff, baseBackoff * pow(2, Double(count - 1)))
    }
}

