import SwiftUI

struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pixelText(size: 11, weight: .medium)
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.65 : 0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DesignTokens.screenRaised)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(DesignTokens.border))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
