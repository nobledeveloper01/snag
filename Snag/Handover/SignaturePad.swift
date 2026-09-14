// A signature on glass. Strokes drawn by a finger, rendered to a picture
// that is hashed and named in the counter-signature the way a photograph
// is named in the report.
import SwiftUI

struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]
    let palette: Palette
    @State private var current: [CGPoint] = []

    var body: some View {
        Canvas { ctx, size in
            for stroke in strokes + [current] where stroke.count > 1 {
                var path = Path()
                path.move(to: stroke[0])
                for p in stroke.dropFirst() { path.addLine(to: p) }
                ctx.stroke(path, with: .color(palette.textPrimary), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
        }
        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
        // High priority, so a stroke that starts on the pad is a stroke and
        // not a scroll of the sheet behind it.
        .highPriorityGesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { current.append($0.location) }
            .onEnded { _ in strokes.append(current); current = [] })
        .accessibilityLabel(Strings.signHere)
        .accessibilityValue(strokes.isEmpty ? "" : "\(strokes.count)")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    /// The signature as a picture: black on white, 600 × 240, JPEG.
    @MainActor
    static func image(of strokes: [[CGPoint]], size: CGSize) -> Data? {
        let renderer = ImageRenderer(content: SignatureImage(strokes: strokes, size: size))
        renderer.scale = 2
        return renderer.uiImage?.jpegData(compressionQuality: 0.9)
    }

    private struct SignatureImage: View {
        let strokes: [[CGPoint]]
        let size: CGSize
        var body: some View {
            Canvas { ctx, _ in
                for stroke in strokes where stroke.count > 1 {
                    var path = Path()
                    path.move(to: stroke[0])
                    for p in stroke.dropFirst() { path.addLine(to: p) }
                    ctx.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: size.width, height: size.height)
            .background(Color.white)
        }
    }
}
