import Foundation

public struct SemanticVersion: Comparable, Equatable, Sendable {
    public let components: [Int]

    public init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let core = trimmed.split(separator: "-", maxSplits: 1).first ?? ""
        let parsed = core.split(separator: ".").map { Int($0) }
        guard !parsed.isEmpty, parsed.allSatisfy({ $0 != nil }) else { return nil }
        self.components = parsed.compactMap { $0 }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}
