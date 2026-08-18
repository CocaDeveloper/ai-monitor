import Foundation

public struct AppPreferences: Codable, Equatable, Sendable {
    public enum Theme: String, Codable, CaseIterable, Sendable {
        case retroBeige
        case darkCRT
        case system
    }

    public var refreshIntervalMinutes = 15
    public var showResetCountdown = true
    public var showWarningIndicator = true
    public var checkForUpdates = true
    public var showProgressBars = true
    public var compactMode = false
    public var theme: Theme = .retroBeige
    public var customCodexPath: String?

    public init() {}
}

public struct PersistedState: Codable, Equatable, Sendable {
    public var accounts: [ProviderAccount]
    public var snapshots: [UUID: UsageSnapshot]
    public var preferences: AppPreferences

    public init(accounts: [ProviderAccount] = [], snapshots: [UUID: UsageSnapshot] = [:], preferences: AppPreferences = .init()) {
        self.accounts = accounts
        self.snapshots = snapshots
        self.preferences = preferences
    }
}

