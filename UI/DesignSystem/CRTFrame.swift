import SwiftUI

struct CRTFrame<Content: View>: View {
    @ViewBuilder let content: Content
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            chassis
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(screenColor)
                    scanlines
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    content
                        .padding(18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.82), lineWidth: 4)
                }
                .padding(.top, 14)
                .padding(.horizontal, 14)
                .padding(.bottom, 7)

                hardwarePanel
                    .frame(height: 42)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.54), lineWidth: 2)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.13))
                .frame(height: 4)
                .padding(.horizontal, 16)
        }
    }

    private var chassis: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: bezelColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.24), lineWidth: 5)
                    .blur(radius: 1)
            }
    }

    private var scanlines: some View {
        Canvas { context, size in
            for y in stride(from: 1.0, through: size.height, by: 4.0) {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.white.opacity(0.018))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var hardwarePanel: some View {
        HStack {
            spectrumMark
            Spacer()
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.72))
                    .frame(width: 58, height: 7)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                    }
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignTokens.phosphorGreen)
                    .frame(width: 12, height: 7)
                    .shadow(color: DesignTokens.phosphorGreen.opacity(0.55), radius: 3)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 3))
        }
    }

    private var spectrumMark: some View {
        HStack(alignment: .bottom, spacing: 1) {
            Rectangle().fill(DesignTokens.danger).frame(width: 3, height: 7)
            Rectangle().fill(DesignTokens.amber).frame(width: 3, height: 11)
            Rectangle().fill(DesignTokens.phosphorGreen).frame(width: 3, height: 15)
            Rectangle().fill(DesignTokens.connectionBlue).frame(width: 3, height: 9)
        }
        .padding(5)
        .background(screenColor, in: RoundedRectangle(cornerRadius: 3))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
        }
        .accessibilityHidden(true)
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
