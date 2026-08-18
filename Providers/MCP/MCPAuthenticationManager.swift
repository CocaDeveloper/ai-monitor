import Foundation

public struct MCPAuthenticationManager: Sendable {
    private let keychain: KeychainStore

    public init(keychain: KeychainStore = .init(service: "dev.aimonitor.mcp")) {
        self.keychain = keychain
    }

    public func storeBearerToken(_ token: String, for configuration: MCPServerConfiguration) throws {
        try keychain.set(Data(token.utf8), account: configuration.id.uuidString)
    }

    public func bearerToken(for configuration: MCPServerConfiguration) throws -> String? {
        try keychain.data(account: configuration.id.uuidString).flatMap { String(data: $0, encoding: .utf8) }
    }

    public func removeCredentials(for configuration: MCPServerConfiguration) throws {
        try keychain.remove(account: configuration.id.uuidString)
    }
}

