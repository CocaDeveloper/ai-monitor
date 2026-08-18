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
    public var showDockIcon = true

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case refreshIntervalMinutes
        case showResetCountdown
        case showWarningIndicator
        case checkForUpdates
        case showProgressBars
        case compactMode
        case theme
        case customCodexPath
        case showDockIcon
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        refreshIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 15
        showResetCountdown = try container.decodeIfPresent(Bool.self, forKey: .showResetCountdown) ?? true
        showWarningIndicator = try container.decodeIfPresent(Bool.self, forKey: .showWarningIndicator) ?? true
        checkForUpdates = try container.decodeIfPresent(Bool.self, forKey: .checkForUpdates) ?? true
        showProgressBars = try container.decodeIfPresent(Bool.self, forKey: .showProgressBars) ?? true
        compactMode = try container.decodeIfPresent(Bool.self, forKey: .compactMode) ?? false
        theme = try container.decodeIfPresent(Theme.self, forKey: .theme) ?? .retroBeige
        customCodexPath = try container.decodeIfPresent(String.self, forKey: .customCodexPath)
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? true
    }
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

