import Foundation

public enum UsageFormatters {
    public static func percent(_ value: Double) -> String {
        String(format: String(localized: "%lld%% left"), locale: .current, Int64(value.rounded()))
    }

    public static func reset(
        _ date: Date?,
        relativeTo now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        guard let date else { return String(localized: "Reset time unavailable") }
        let interval = date.timeIntervalSince(now)
        if interval > 0, interval < 3 * 60 * 60 {
            let totalMinutes = max(1, Int(interval / 60))
            return String(format: String(localized: "Reset in %lldh %lldm"), locale: locale, Int64(totalMinutes / 60), Int64(totalMinutes % 60))
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.timeStyle = .short

        if calendar.isDate(date, inSameDayAs: now) {
            return String(format: String(localized: "Reset Today at %@"), locale: locale, formatter.string(from: date))
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(format: String(localized: "Reset Tomorrow at %@"), locale: locale, formatter.string(from: date))
        }

        formatter.dateFormat = "MMM d"
        return String(format: String(localized: "Reset %@"), locale: locale, formatter.string(from: date))
    }

    public static func updated(_ date: Date?, relativeTo now: Date = .now) -> String {
        guard let date else { return String(localized: "Never updated") }
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        switch seconds {
        case 0..<60: return String(format: String(localized: "Updated %llds ago"), Int64(seconds))
        case 60..<3600: return String(format: String(localized: "Updated %lldm ago"), Int64(seconds / 60))
        default: return String(format: String(localized: "Updated %lldh ago"), Int64(seconds / 3600))
        }
    }

    public static func credits(_ balance: CreditBalance) -> String {
        let number = balance.remaining.rounded() == balance.remaining
            ? String(Int(balance.remaining))
            : String(format: "%.1f", balance.remaining)
        return "\(number) \(balance.unit)"
    }
}
