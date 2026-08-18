import SwiftUI

struct ProgressBlocks: View {
    let percent: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Double(index) < percent / 10 ? DesignTokens.statusColor(remaining: percent) : Color.white.opacity(0.10))
                    .frame(height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usage remaining")
        .accessibilityValue("\(Int(percent.rounded())) percent")
    }
}

