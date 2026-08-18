import Foundation

public struct ProviderID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static let codex: Self = "codex"
    public static let kling: Self = "kling"
    public static let customMCP: Self = "custom-mcp"
    public static let mock: Self = "mock"
}

public enum ProviderCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case percentage
    case credits
    case measuredUsage
    case resetWindows
    case accountDetails
    case multipleLimits
    case notifications
    case browserLogin
}

public enum ConnectionStatus: String, Codable, CaseIterable, Sendable {
    case notConnected
    case openingBrowser
    case waitingForLogin
    case connected
    case refreshing
    case loginCancelled
    case loginFailed
    case reconnectRequired
    case offline
    case unavailable

    public var userFacingText: String {
        switch self {
        case .notConnected: String(localized: "Not Connected")
        case .openingBrowser: String(localized: "Opening Browser")
        case .waitingForLogin: String(localized: "Waiting for Login")
        case .connected: String(localized: "Connected")
        case .refreshing: String(localized: "Refreshing…")
        case .loginCancelled: String(localized: "Login Cancelled")
        case .loginFailed: String(localized: "Login Failed")
        case .reconnectRequired: String(localized: "Reconnect Required")
        case .offline: String(localized: "Offline")
        case .unavailable: String(localized: "Usage unavailable")
        }
    }
}

public struct ProviderAccount: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var providerID: ProviderID
    public var displayName: String
    public var emailHint: String?
    public var planName: String?
    public var sortOrder: Int
    public var status: ConnectionStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        providerID: ProviderID,
        displayName: String,
        emailHint: String? = nil,
        planName: String? = nil,
        sortOrder: Int = 0,
        status: ConnectionStatus = .notConnected,
        createdAt: Date = .now
    ) {
        self.id = id
        self.providerID = providerID
        self.displayName = displayName
        self.emailHint = emailHint
        self.planName = planName
        self.sortOrder = sortOrder
        self.status = status
        self.createdAt = createdAt
    }
}

public struct ResetWindow: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public var label: String
    public var usedPercent: Double?
    public var resetsAt: Date?
    public var durationMinutes: Int?
    public var isPrimary: Bool

    public init(
        id: String,
        label: String,
        usedPercent: Double?,
        resetsAt: Date?,
        durationMinutes: Int?,
        isPrimary: Bool
    ) {
        self.id = id
        self.label = label
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.durationMinutes = durationMinutes
        self.isPrimary = isPrimary
    }

    public var remainingPercent: Double? {
        usedPercent.map { min(100, max(0, 100 - $0)) }
    }
}

public struct CreditBalance: Codable, Hashable, Sendable {
    public var remaining: Double
    public var unit: String
    public var expiresAt: Date?

    public init(remaining: Double, unit: String = "credits", expiresAt: Date? = nil) {
        self.remaining = remaining
        self.unit = unit
        self.expiresAt = expiresAt
    }
}

public enum UsageMetricKind: String, Codable, Sendable {
    case percentage
    case credits
    case measured
    case unavailable
}

public struct UsageMetric: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public var label: String
    public var kind: UsageMetricKind
    public var remainingPercent: Double?
    public var credits: CreditBalance?
    public var used: Double?
    public var limit: Double?
    public var unit: String?
    public var windows: [ResetWindow]

    public init(
        id: String,
        label: String,
        kind: UsageMetricKind,
        remainingPercent: Double? = nil,
        credits: CreditBalance? = nil,
        used: Double? = nil,
        limit: Double? = nil,
        unit: String? = nil,
        windows: [ResetWindow] = []
    ) {
        self.id = id
        self.label = label
        self.kind = kind
        self.remainingPercent = remainingPercent.map { min(100, max(0, $0)) }
        self.credits = credits
        self.used = used
        self.limit = limit
        self.unit = unit
        self.windows = windows
    }
}

public struct UsageSnapshot: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let accountID: UUID
    public var providerID: ProviderID
    public var metrics: [UsageMetric]
    public var connectionStatus: ConnectionStatus
    public var updatedAt: Date
    public var lastErrorCode: String?

    public init(
        id: UUID = UUID(),
        accountID: UUID,
        providerID: ProviderID,
        metrics: [UsageMetric],
        connectionStatus: ConnectionStatus = .connected,
        updatedAt: Date = .now,
        lastErrorCode: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.providerID = providerID
        self.metrics = metrics
        self.connectionStatus = connectionStatus
        self.updatedAt = updatedAt
        self.lastErrorCode = lastErrorCode
    }

    public var primaryMetric: UsageMetric? {
        metrics.first { metric in metric.windows.contains(where: \ResetWindow.isPrimary) } ?? metrics.first
    }
}

public enum ProviderError: Error, LocalizedError, Equatable, Sendable {
    case executableNotFound
    case notConnected
    case loginCancelled
    case loginFailed(String)
    case timeout
    case processCrashed(Int32)
    case incompatibleVersion(String)
    case malformedResponse
    case noUsageData
    case authenticationRequired
    case unsafeOperationBlocked
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound: String(localized: "Codex CLI not found")
        case .notConnected: String(localized: "Login required")
        case .loginCancelled: String(localized: "Login was cancelled")
        case .loginFailed: String(localized: "Login failed")
        case .timeout: String(localized: "The provider did not respond in time")
        case .processCrashed: String(localized: "The provider process stopped unexpectedly")
        case .incompatibleVersion: String(localized: "This provider version is not compatible")
        case .malformedResponse: String(localized: "The provider returned an unreadable response")
        case .noUsageData: String(localized: "No usage data was provided")
        case .authenticationRequired: String(localized: "Authentication is required")
        case .unsafeOperationBlocked: String(localized: "AI Monitor blocked an operation that could change your account")
        case .transport: String(localized: "Could not connect to the provider")
        }
    }
}
