// The Snag mark: a room from above, its door, and a crack. Drawn in code so
// the splash can bloom it; `scripts/brandmark.py` draws the same shape for
// the icon and docs/mark.png.
import SwiftUI

struct Mark: View {
    var size: CGFloat = 96
    var color: Color
    var ground: Color

    var body: some View {
        Canvas { context, bounds in
            let w = bounds.width, h = bounds.height
            let stroke = max(2, w * 0.045)
            let room = CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.64, height: h * 0.64)
            context.stroke(Path(roundedRect: room, cornerRadius: w * 0.09), with: .color(color), lineWidth: stroke)
            // The door: a gap in the bottom wall.
            context.fill(Path(CGRect(x: w * 0.40, y: h * 0.82 - stroke, width: w * 0.20, height: stroke * 2)), with: .color(ground))
            // The snag: a crack.
            var crack = Path()
            crack.move(to: CGPoint(x: w * 0.56, y: h * 0.30))
            crack.addLine(to: CGPoint(x: w * 0.62, y: h * 0.40))
            crack.addLine(to: CGPoint(x: w * 0.57, y: h * 0.47))
            crack.addLine(to: CGPoint(x: w * 0.66, y: h * 0.58))
            context.stroke(crack, with: .color(color), style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
