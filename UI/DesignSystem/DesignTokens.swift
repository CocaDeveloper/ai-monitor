import SwiftUI

enum DesignTokens {
    static let beige = Color(red: 0.86, green: 0.80, blue: 0.65)
    static let beigeHighlight = Color(red: 0.96, green: 0.91, blue: 0.77)
    static let beigeShadow = Color(red: 0.42, green: 0.38, blue: 0.30)
    static let screen = Color(red: 0.055, green: 0.065, blue: 0.063)
    static let screenRaised = Color(red: 0.09, green: 0.105, blue: 0.10)
    static let phosphorGreen = Color(red: 0.49, green: 0.82, blue: 0.25)
    static let amber = Color(red: 0.97, green: 0.68, blue: 0.18)
    static let danger = Color(red: 0.96, green: 0.28, blue: 0.17)
    static let connectionBlue = Color(red: 0.23, green: 0.58, blue: 0.94)
    static let muted = Color.white.opacity(0.58)
    static let border = Color.white.opacity(0.16)

    static func statusColor(remaining: Double?) -> Color {
        guard let remaining else { return muted }
        if remaining <= 20 { return danger }
        if remaining <= 45 { return amber }
        return phosphorGreen
    }
}

extension View {
    func pixelText(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight, design: .monospaced))
    }
}

