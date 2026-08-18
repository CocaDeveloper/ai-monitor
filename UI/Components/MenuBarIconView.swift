import SwiftUI

struct MenuBarIconView: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 18, size.height / 16)
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, shade: Double = 1) {
                context.fill(Path(CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale)), with: .color(.primary.opacity(shade)))
            }
            rect(2, 1, 14, 12)
            context.fill(Path(CGRect(x: 4 * scale, y: 3 * scale, width: 10 * scale, height: 7 * scale)), with: .color(.clear))
            context.stroke(Path(CGRect(x: 4 * scale, y: 3 * scale, width: 10 * scale, height: 7 * scale)), with: .color(.primary), lineWidth: scale)
            rect(7, 13, 4, 1)
            rect(5, 15, 8, 1)
            rect(6, 6, 1, 1)
            rect(11, 6, 1, 1)
            rect(8, 8, 2, 1)
        }
        .frame(width: 18, height: 16)
        .accessibilityHidden(true)
    }
}

