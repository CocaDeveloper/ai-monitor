import SwiftUI

struct CRTFrame<Content: View>: View {
    @ViewBuilder let content: Content
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: bezelColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.48), lineWidth: 2)
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(screenColor)
                .overlay {
                    LinearGradient(
                        colors: [Color.white.opacity(0.045), .clear, Color.black.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.72), lineWidth: 5)
                }
                .padding(18)
            content
                .padding(32)
        }
        .shadow(color: .black.opacity(0.34), radius: 22, y: 14)
        .padding(16)
    }

    private var usesDarkCRT: Bool {
        environment.preferences.theme == .darkCRT || (environment.preferences.theme == .system && colorScheme == .dark)
    }

    private var bezelColors: [Color] {
        usesDarkCRT
            ? [Color(red: 0.24, green: 0.27, blue: 0.25), Color(red: 0.11, green: 0.13, blue: 0.12), .black.opacity(0.92)]
            : [DesignTokens.beigeHighlight, DesignTokens.beige, DesignTokens.beigeShadow.opacity(0.78)]
    }

    private var screenColor: Color { usesDarkCRT ? .black : DesignTokens.screen }
}
