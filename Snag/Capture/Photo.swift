// What happens to a photograph between the sensor and the hash: the
// metadata comes off, and the picture is judged for darkness and blur.
// Both are done before the bytes are hashed, because the bytes that are
// hashed are the photograph — there is no other copy.
import CoreGraphics
import Foundation
import ImageIO
import UIKit

enum Photo {
    /// Nothing but the picture. Re-encoded through a renderer, which
    /// writes no EXIF, no GPS, no maker note and bakes the orientation
    /// in — so a bundle shared with a landlord carries no location.
    static func strip(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.85) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// The metadata dictionaries a JPEG carries, for the test that proves
    /// `strip` leaves none of the ones that matter.
    static func metadataKeys(_ data: Data) -> Set<String> {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] else { return [] }
        return Set(props.keys)
    }

    static func metadata(_ data: Data, _ dictionary: CFString) -> [String: Any] {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] else { return [:] }
        return props[dictionary as String] as? [String: Any] ?? [:]
    }

    enum Issue: Equatable { case dark, blurred }

    /// Judged on a 96-pixel-wide grey copy: mean luminance for darkness, the
    /// variance of a Laplacian for blur. Thresholds set by the fixtures in
    /// `PhotoTests`; a wrong verdict here costs a retake, not a report.
    static func judge(_ data: Data) -> [Issue] {
        guard let image = UIImage(data: data)?.cgImage else { return [] }
        let w = 96, h = max(1, Int(Double(image.height) * 96.0 / Double(image.width)))
        var pixels = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return [] }
        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let mean = pixels.reduce(0) { $0 + Int($1) } / pixels.count
        var issues: [Issue] = []
        if mean < darkBelow { issues.append(.dark) }
        // Laplacian: 4·centre − neighbours, over the interior.
        var sum = 0.0, sumSq = 0.0, n = 0.0
        if w > 2 && h > 2 {
            for y in 1..<(h - 1) {
                for x in 1..<(w - 1) {
                    let c = Int(pixels[y * w + x])
                    let l = 4 * c - Int(pixels[y * w + x - 1]) - Int(pixels[y * w + x + 1]) - Int(pixels[(y - 1) * w + x]) - Int(pixels[(y + 1) * w + x])
                    sum += Double(l); sumSq += Double(l * l); n += 1
                }
            }
        }
        let variance = n > 0 ? sumSq / n - (sum / n) * (sum / n) : 0
        if variance < blurBelow && !issues.contains(.dark) { issues.append(.blurred) }
        return issues
    }

    static let darkBelow = 40       // of 255
    static let blurBelow = 12.0     // Laplacian variance at 96 px wide
}
