import Foundation

public actor MCPClient {
    private let configuration: MCPServerConfiguration
    private let authentication: MCPAuthenticationManager
    private let discovery = MCPDiscoveryService()
    private let session: URLSession
    private var nextID = 1

    public init(configuration: MCPServerConfiguration, authentication: MCPAuthenticationManager = .init(), session: URLSession = .shared) {
        self.configuration = configuration
        self.authentication = authentication
        self.session = session
    }

    public func discoverTools() async throws -> [MCPTool] {
        let response: ToolListResult = try await request(method: "tools/list", params: .object([:]))
        return discovery.readOnlyMonitoringTools(from: response.tools)
    }

    public func callReadOnlyTool(name: String, arguments: [String: JSONValue] = [:]) async throws -> JSONValue {
        guard discovery.permitsAutomaticCall(toolName: name, explicitAllowlist: configuration.allowedReadOnlyTools) else {
            throw ProviderError.unsafeOperationBlocked
        }
        let response: ToolCallResult = try await request(
            method: "tools/call",
            params: .object(["name": .string(name), "arguments": .object(arguments)])
        )
        return response.structuredContent ?? .array(response.content ?? [])
    }

    private func request<Result: Decodable>(method: String, params: JSONValue) async throws -> Result {
        guard case let .streamableHTTP(endpoint) = configuration.transport else {
            throw ProviderError.transport("stdio MCP is not enabled in this beta")
        }
        guard Self.isSecureEndpoint(endpoint) else {
            throw ProviderError.transport("MCP endpoints must use HTTPS, except for loopback development")
        }
        let id = nextID
        nextID += 1
        let body = MCPRequest(id: id, method: method, params: params)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        if let token = try authentication.bearerToken(for: configuration) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ProviderError.transport("MCP request failed")
        }
        let envelope = try JSONDecoder().decode(MCPResponse<Result>.self, from: data)
        if let error = envelope.error { throw ProviderError.transport(error.message) }
        guard let result = envelope.result else { throw ProviderError.malformedResponse }
        return result
    }

    private static func isSecureEndpoint(_ endpoint: URL) -> Bool {
        if endpoint.scheme?.lowercased() == "https" { return true }
        guard endpoint.scheme?.lowercased() == "http", let host = endpoint.host?.lowercased() else { return false }
        return ["localhost", "127.0.0.1", "::1"].contains(host)
    }
}

private struct MCPRequest: Encodable {
    let jsonrpc = "2.0"
    let id: Int
    let method: String
    let params: JSONValue
}

private struct MCPResponse<Result: Decodable>: Decodable {
    let result: Result?
    let error: JSONRPCErrorBody?
}

private struct ToolListResult: Decodable {
    let tools: [MCPTool]
}

private struct ToolCallResult: Decodable {
    let content: [JSONValue]?
    let structuredContent: JSONValue?
}
