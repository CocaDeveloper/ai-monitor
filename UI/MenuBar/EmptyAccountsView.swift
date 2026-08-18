import SwiftUI

struct EmptyAccountsView: View {
    let add: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6).stroke(DesignTokens.muted, lineWidth: 2).frame(width: 72, height: 50)
                Image(systemName: "waveform.path.ecg").foregroundStyle(DesignTokens.phosphorGreen)
            }
            Text("No accounts yet").pixelText(size: 15, weight: .semibold).foregroundStyle(.white)
            Text("Connect Codex to see limits and reset times here.")
                .pixelText(size: 11)
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.center)
            Button("+ Add Account", action: add).buttonStyle(RetroButtonStyle())
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

