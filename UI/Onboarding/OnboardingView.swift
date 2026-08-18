import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var page = 0
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        CRTFrame {
            VStack(spacing: 22) {
                Spacer()
                illustration
                Text(title).pixelText(size: 20, weight: .bold).foregroundStyle(.white)
                Text(message)
                    .pixelText(size: 13)
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Spacer()
                if page == 2 {
                    VStack(spacing: 9) {
                        Button("Codex / OpenAI") { finish(openAddAccount: true) }.buttonStyle(RetroButtonStyle())
                        Button("Kling (Beta)") { finish(openAddAccount: true) }.buttonStyle(RetroButtonStyle())
                        Button("Set up later") { finish(openAddAccount: false) }.buttonStyle(.plain).foregroundStyle(DesignTokens.muted)
                    }
                } else {
                    Button(page == 0 ? "Get Started" : "Continue") { withAnimation(.easeOut(duration: 0.18)) { page += 1 } }
                        .buttonStyle(RetroButtonStyle())
                }
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle().fill(index == page ? DesignTokens.phosphorGreen : Color.white.opacity(0.18)).frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .accessibilityElement(children: .contain)
    }

    private var title: LocalizedStringKey {
        ["Welcome to AI Monitor", "Private by default", "Connect your first account"][page]
    }

    private var message: LocalizedStringKey {
        [
            "See your AI usage, resets and credits from one tiny menu bar monitor.",
            "Your accounts stay on this Mac. AI Monitor does not collect your passwords or usage history.",
            "Start with Codex / OpenAI. You can add more accounts at any time.",
        ][page]
    }

    private var illustration: some View {
        Image(systemName: page == 0 ? "menubar.rectangle" : page == 1 ? "lock.shield" : "person.crop.circle.badge.plus")
            .font(.system(size: 42, weight: .light))
            .foregroundStyle(page == 1 ? DesignTokens.connectionBlue : DesignTokens.phosphorGreen)
            .accessibilityHidden(true)
    }

    private func finish(openAddAccount: Bool) {
        hasCompletedOnboarding = true
        if openAddAccount { environment.addAccountPresented = true }
    }
}
