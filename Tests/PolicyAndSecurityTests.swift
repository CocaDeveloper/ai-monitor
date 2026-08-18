import Foundation
import XCTest

final class PolicyAndSecurityTests: XCTestCase {
    func testLocalDeveloperOverridesFollowPublicDefaults() throws {
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let config = try String(
            contentsOf: repository.appendingPathComponent("Config/Project.xcconfig"),
            encoding: .utf8
        )
        let defaults = try XCTUnwrap(config.range(of: "AIMONITOR_BUNDLE_ID = dev.aimonitor.app"))
        let override = try XCTUnwrap(config.range(of: "#include? \"Developer.xcconfig\""))

        XCTAssertGreaterThan(override.lowerBound, defaults.lowerBound)
        XCTAssertTrue(config.contains("AIMONITOR_CODE_SIGN_STYLE = Automatic"))

        let generator = try String(
            contentsOf: repository.appendingPathComponent("scripts/generate-xcodeproj.py"),
            encoding: .utf8
        )
        XCTAssertTrue(generator.contains("\"CODE_SIGN_STYLE\": '\"$(AIMONITOR_CODE_SIGN_STYLE)\"'"))
        XCTAssertEqual(generator.components(separatedBy: "\"ENABLE_HARDENED_RUNTIME\": \"YES\"").count - 1, 2)
    }

    func testAppDeclaresUtilitiesCategory() throws {
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let plist = try String(
            contentsOf: repository.appendingPathComponent("Config/App-Info.plist"),
            encoding: .utf8
        )
        XCTAssertTrue(plist.contains("public.app-category.utilities"))
    }

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
