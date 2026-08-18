import Foundation
import XCTest

final class FormattingTests: XCTestCase {
    func testResetWithinThreeHoursUsesCountdown() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(UsageFormatters.reset(now.addingTimeInterval(2 * 3600 + 14 * 60), relativeTo: now), "Reset in 2h 14m")
    }

    func testResetUsesProvidedTimezone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: -5 * 3600)!
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!
        let later = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 18))!
        let value = UsageFormatters.reset(later, relativeTo: now, calendar: calendar, locale: Locale(identifier: "en_US_POSIX"))
        XCTAssertEqual(value.replacingOccurrences(of: "\u{202F}", with: " "), "Reset Today at 6:00 PM")
    }

    func testUpdatedFormatting() {
        let now = Date(timeIntervalSince1970: 1000)
        XCTAssertEqual(UsageFormatters.updated(Date(timeIntervalSince1970: 880), relativeTo: now), "Updated 2m ago")
    }

    func testCreditFormatting() {
        XCTAssertEqual(UsageFormatters.credits(.init(remaining: 540)), "540 credits")
    }
}
