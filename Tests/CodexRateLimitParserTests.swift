import Foundation
import XCTest

final class CodexRateLimitParserTests: XCTestCase {
    func testDecodesUnknownFieldsAndMultipleLimitIDs() throws {
        let data = try fixture("codex-rate-limits.json")
        let decoded = try JSONDecoder().decode(CodexRateLimitsResult.self, from: data)
        let snapshot = try CodexRateLimitParser.snapshot(from: decoded, accountID: UUID())
        XCTAssertEqual(snapshot.metrics.count, 2)
        XCTAssertEqual(snapshot.metrics.first(where: { $0.id == "codex" })?.remainingPercent, 75)
    }

    func testPreservesPrimaryAndSecondaryWindows() throws {
        let decoded = try JSONDecoder().decode(CodexRateLimitsResult.self, from: fixture("codex-rate-limits.json"))
        let metric = try CodexRateLimitParser.snapshot(from: decoded, accountID: UUID()).metrics.first { $0.id == "codex" }
        XCTAssertEqual(metric?.windows.count, 2)
        XCTAssertEqual(metric?.windows.first(where: \ResetWindow.isPrimary)?.durationMinutes, 300)
        XCTAssertEqual(metric?.windows.first(where: { !$0.isPrimary })?.durationMinutes, 10080)
    }

    func testConvertsUnixTimestampSeconds() throws {
        let decoded = try JSONDecoder().decode(CodexRateLimitsResult.self, from: fixture("codex-rate-limits.json"))
        let window = try XCTUnwrap(try CodexRateLimitParser.snapshot(from: decoded, accountID: UUID()).metrics.first?.windows.first)
        XCTAssertEqual(window.resetsAt?.timeIntervalSince1970, 1_730_947_200)
    }

    func testMissingUsageThrowsHonestUnavailableError() throws {
        let decoded = try JSONDecoder().decode(CodexRateLimitsResult.self, from: fixture("codex-rate-limits-missing.json"))
        XCTAssertThrowsError(try CodexRateLimitParser.snapshot(from: decoded, accountID: UUID())) { error in
            XCTAssertEqual(error as? ProviderError, .noUsageData)
        }
    }

    func testDecodesCreditBalanceReturnedAsString() throws {
        let data = Data(#"{"rateLimits":{"credits":{"hasCredits":true,"unlimited":false,"balance":"42.5"}}}"#.utf8)
        let decoded = try JSONDecoder().decode(CodexRateLimitsResult.self, from: data)
        XCTAssertEqual(decoded.rateLimits?.credits?.balance, 42.5)
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name.replacingOccurrences(of: ".json", with: ""), withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
