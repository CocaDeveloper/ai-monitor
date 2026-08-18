import Foundation

public enum CodexRPCMethod: String, Sendable {
    case initialize
    case initialized
    case accountRead = "account/read"
    case accountLoginStart = "account/login/start"
    case accountLoginCompleted = "account/login/completed"
    case accountUpdated = "account/updated"
    case accountLoginCancel = "account/login/cancel"
    case accountLogout = "account/logout"
    case accountRateLimitsRead = "account/rateLimits/read"
    case accountRateLimitsUpdated = "account/rateLimits/updated"
}

public struct EmptyParams: Codable, Sendable { public init() {} }
public struct EmptyResult: Codable, Sendable { public init() {} }

public struct CodexInitializeParams: Codable, Sendable {
    public struct ClientInfo: Codable, Sendable {
        let name: String
        let title: String
        let version: String
    }
    let clientInfo: ClientInfo

    public init(version: String) {
        self.clientInfo = .init(name: "ai_monitor", title: "AI Monitor", version: version)
    }
}

public struct CodexAccountReadParams: Codable, Sendable {
    let refreshToken: Bool
    public init(refreshToken: Bool = false) { self.refreshToken = refreshToken }
}

public struct CodexAccountReadResult: Codable, Sendable {
    public struct Account: Codable, Sendable {
        public let type: String
        public let email: String?
        public let planType: String?
        public let credentialSource: String?
    }
    public let account: Account?
    public let requiresOpenaiAuth: Bool
}

public struct CodexLoginStartParams: Encodable, Sendable {
    let type = "chatgpt"
    let useHostedLoginSuccessPage = true
    let appBrand = "chatgpt"
    public init() {}
}

public struct CodexLoginStartResult: Codable, Sendable {
    public let type: String
    public let loginId: String?
    public let authUrl: URL?
}

public struct CodexLoginCancelParams: Codable, Sendable {
    let loginId: String
    public init(loginId: String) { self.loginId = loginId }
}

public struct CodexLoginCompleted: Codable, Sendable {
    public let loginId: String?
    public let success: Bool
    public let error: String?
}

public struct CodexRateWindow: Codable, Sendable {
    public let usedPercent: Double?
    public let windowDurationMins: Int?
    public let resetsAt: Double?
}

public struct CodexWorkspaceCredits: Codable, Sendable {
    public let hasCredits: Bool?
    public let unlimited: Bool?
    public let balance: Double?
}

public struct CodexRateLimit: Codable, Sendable {
    public let limitId: String?
    public let limitName: String?
    public let primary: CodexRateWindow?
    public let secondary: CodexRateWindow?
    public let credits: CodexWorkspaceCredits?
    public let planType: String?
    public let rateLimitReachedType: String?
}

public struct CodexRateLimitsResult: Codable, Sendable {
    public let rateLimits: CodexRateLimit?
    public let rateLimitsByLimitId: [String: CodexRateLimit]?
}

public struct JSONRPCErrorBody: Codable, Sendable {
    public let code: Int?
    public let message: String
}

public struct JSONRPCEnvelope<Result: Decodable>: Decodable {
    public let id: Int?
    public let result: Result?
    public let error: JSONRPCErrorBody?
}
