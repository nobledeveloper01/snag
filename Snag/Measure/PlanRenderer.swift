// The floor plan as a picture: walls as lines, doors and windows as gaps,
// the dimensions along two sides, a scale bar. Drawn from `ScannedFloor`,
// so the same picture comes from a RoomPlan scan and from the fixture. The
// JPEG goes into the bundle as a photograph does — by its hash, named in
// the report as `planHash`, checked by both verifiers.
import SnagDomain
import UIKit

enum PlanRenderer {
    static let size = CGSize(width: 1200, height: 900)

    static func jpeg(_ floor: ScannedFloor, label: String) -> Data? {
        let xs = floor.corners.map(\.x), ys = floor.corners.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max(), maxX > minX, maxY > minY else { return nil }
        let margin: CGFloat = 120
        let scale = min((size.width - 2 * margin) / CGFloat(maxX - minX), (size.height - 2 * margin) / CGFloat(maxY - minY))
        func p(_ c: Corner) -> CGPoint {
            CGPoint(x: margin + CGFloat(c.x - minX) * scale, y: size.height - margin - CGFloat(c.y - minY) * scale)
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.9) { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            // The floor, faintly, then the walls.
            let poly = UIBezierPath()
            for (i, c) in floor.corners.enumerated() { i == 0 ? poly.move(to: p(c)) : poly.addLine(to: p(c)) }
            poly.close()
            UIColor(white: 0.94, alpha: 1).setFill(); poly.fill()
            UIColor.black.setStroke()
            for (a, b) in floor.walls {
                let path = UIBezierPath(); path.move(to: p(a)); path.addLine(to: p(b)); path.lineWidth = 6; path.stroke()
            }
            // Openings, as white gaps with a thin line across.
            for (a, b) in floor.openings {
                let gap = UIBezierPath(); gap.move(to: p(a)); gap.addLine(to: p(b)); gap.lineWidth = 10
                UIColor.white.setStroke(); gap.stroke()
                let thin = UIBezierPath(); thin.move(to: p(a)); thin.addLine(to: p(b)); thin.lineWidth = 2
                UIColor.darkGray.setStroke(); thin.stroke()
            }
            // Dimensions along the bottom and the right.
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 34, weight: .medium), .foregroundColor: UIColor.darkGray]
            let w = String(format: "%.2f m", maxX - minX), h = String(format: "%.2f m", maxY - minY)
            (w as NSString).draw(at: CGPoint(x: size.width / 2 - 60, y: size.height - margin + 30), withAttributes: attrs)
            let hSize = (h as NSString).size(withAttributes: attrs)
            (h as NSString).draw(at: CGPoint(x: size.width - margin + 20, y: size.height / 2 - hSize.height / 2), withAttributes: attrs)
            // A metre, for scale, and the label.
            let bar = UIBezierPath(); bar.move(to: CGPoint(x: margin, y: 60)); bar.addLine(to: CGPoint(x: margin + scale, y: 60)); bar.lineWidth = 4
            UIColor.black.setStroke(); bar.stroke()
            ("1 m" as NSString).draw(at: CGPoint(x: margin, y: 68), withAttributes: attrs)
            (label as NSString).draw(at: CGPoint(x: size.width - margin - 300, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 40, weight: .semibold), .foregroundColor: UIColor.black])
        }
    }
}
