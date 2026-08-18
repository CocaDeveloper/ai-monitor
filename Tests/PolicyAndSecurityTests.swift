import Foundation
import XCTest

final class PolicyAndSecurityTests: XCTestCase {
    func testRefreshCooldown() {
        let policy = RefreshPolicy(cooldown: 60)
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertFalse(policy.canRefresh(lastAttempt: Date(timeIntervalSince1970: 50), now: now))
        XCTAssertTrue(policy.canRefresh(lastAttempt: Date(timeIntervalSince1970: 39), now: now))
    }

    func testExponentialBackoffCaps() {
        let policy = RefreshPolicy(baseBackoff: 30, maximumBackoff: 120)
        XCTAssertEqual(policy.backoff(afterFailureCount: 1), 30)
        XCTAssertEqual(policy.backoff(afterFailureCount: 3), 120)
        XCTAssertEqual(policy.backoff(afterFailureCount: 8), 120)
    }

    func testLoggerRedactsTokensAndEmails() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let text = "Authorization: Bearer secret-token email person@example.com sk-abcdefghijk callback?code=private-code Cookie: session=private-cookie path \(home)/Codex"
        let safe = SanitizedLogger.sanitize(text)
        XCTAssertFalse(safe.contains("secret-token"))
        XCTAssertFalse(safe.contains("person@example.com"))
        XCTAssertFalse(safe.contains("sk-abcdefghijk"))
        XCTAssertFalse(safe.contains("private-code"))
        XCTAssertFalse(safe.contains("private-cookie"))
        XCTAssertFalse(safe.contains(home))
    }

    func testSemanticVersionComparison() throws {
        XCTAssertLessThan(try XCTUnwrap(SemanticVersion("v1.2.3")), try XCTUnwrap(SemanticVersion("1.3.0")))
        XCTAssertEqual(SemanticVersion("1.2"), SemanticVersion("1.2.0"))
    }

    func testMCPDiscoveryAllowsReadOnlyUsageTools() {
        let service = MCPDiscoveryService()
        let tools = [
            MCPTool(name: "get_credit_balance", description: nil, inputSchema: nil),
            MCPTool(name: "generate_video", description: "spends credits", inputSchema: nil),
            MCPTool(name: "delete_account", description: nil, inputSchema: nil),
        ]
        XCTAssertEqual(service.readOnlyMonitoringTools(from: tools).map(\.name), ["get_credit_balance"])
        XCTAssertFalse(service.permitsAutomaticCall(toolName: "get_credit_balance", explicitAllowlist: []))
        XCTAssertTrue(service.permitsAutomaticCall(toolName: "get_credit_balance", explicitAllowlist: ["get_credit_balance"]))
        XCTAssertFalse(service.permitsAutomaticCall(toolName: "generate_video", explicitAllowlist: ["generate_video"]))
    }
}
