import Foundation

public enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else { self = .array(try container.decode([JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

public enum MCPTransport: Codable, Hashable, Sendable {
    case streamableHTTP(URL)
    case standardIO(executable: String, arguments: [String])
}

public struct MCPServerConfiguration: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public var transport: MCPTransport
    public var isCommunityServer: Bool
    public var credentialKeychainAccount: String?
    public var allowedReadOnlyTools: Set<String>

    public init(id: UUID = UUID(), displayName: String, transport: MCPTransport, isCommunityServer: Bool = false, credentialKeychainAccount: String? = nil, allowedReadOnlyTools: Set<String> = []) {
        self.id = id
        self.displayName = displayName
        self.transport = transport
        self.isCommunityServer = isCommunityServer
        self.credentialKeychainAccount = credentialKeychainAccount
        self.allowedReadOnlyTools = allowedReadOnlyTools
    }
}

public struct MCPTool: Codable, Hashable, Sendable {
    public let name: String
    public let description: String?
    public let inputSchema: JSONValue?
}

public struct MCPConnection: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let configurationID: UUID
    public var connectedAt: Date
    public var discoveredTools: [MCPTool]
}
