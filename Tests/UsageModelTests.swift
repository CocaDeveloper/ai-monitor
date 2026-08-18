import XCTest

final class UsageModelTests: XCTestCase {
    func testRemainingPercent() {
        XCTAssertEqual(ResetWindow(id: "a", label: "A", usedPercent: 62, resetsAt: nil, durationMinutes: nil, isPrimary: true).remainingPercent, 38)
    }

    func testRemainingPercentClampsLow() {
        XCTAssertEqual(ResetWindow(id: "a", label: "A", usedPercent: 150, resetsAt: nil, durationMinutes: nil, isPrimary: true).remainingPercent, 0)
    }

    func testRemainingPercentClampsHigh() {
        XCTAssertEqual(ResetWindow(id: "a", label: "A", usedPercent: -20, resetsAt: nil, durationMinutes: nil, isPrimary: true).remainingPercent, 100)
    }

    func testMetricAcceptsMeasuredUsage() {
        let metric = UsageMetric(id: "minutes", label: "Minutes", kind: .measured, used: 43, limit: 1000, unit: "minutes")
        XCTAssertEqual(metric.used, 43)
        XCTAssertEqual(metric.limit, 1000)
        XCTAssertNil(metric.credits)
    }

    func testCapabilitiesRemainProviderSpecific() {
        let provider = MockProvider.codex()
        XCTAssertTrue(provider.capabilities.contains(.multipleLimits))
        XCTAssertTrue(provider.capabilities.contains(.credits))
    }
}

