import SwiftUI

struct MenuBarIconView: View {
    var body: some View {
        Image(systemName: "display")
            .symbolRenderingMode(.monochrome)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 18, height: 16)
        .accessibilityHidden(true)
    }
}
