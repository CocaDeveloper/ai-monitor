import Foundation

public struct MCPDiscoveryService: Sendable {
    private static let readSignals = ["balance", "credit", "quota", "usage", "billing", "subscription", "account", "resource_package", "resource-package"]
    private static let unsafeSignals = ["generate", "create_video", "create_image", "delete", "purchase", "buy", "topup", "top_up", "update", "cancel_subscription"]

    public init() {}

    public func readOnlyMonitoringTools(from tools: [MCPTool]) -> [MCPTool] {
        tools.filter { tool in
            let candidate = "\(tool.name) \(tool.description ?? "")".lowercased()
            return Self.readSignals.contains(where: candidate.contains)
                && !Self.unsafeSignals.contains(where: candidate.contains)
        }
    }

    public func permitsAutomaticCall(toolName: String, explicitAllowlist: Set<String>) -> Bool {
        let name = toolName.lowercased()
        return explicitAllowlist.contains(toolName)
            && Self.readSignals.contains(where: name.contains)
            && !Self.unsafeSignals.contains(where: name.contains)
    }
}
