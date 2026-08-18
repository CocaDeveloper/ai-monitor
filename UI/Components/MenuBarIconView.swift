import SwiftUI

struct MenuBarIconView: View {
    var body: some View {
        Image(systemName: "macwindow")
            .symbolRenderingMode(.monochrome)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 14, height: 14)
        .accessibilityHidden(true)
    }
}
