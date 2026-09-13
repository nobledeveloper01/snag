// Every pair DESIGN.md promises, measured: 4.5:1 for text, 3:1 for the
// colours that carry state, on every ground including both gradient stops,
// in both themes. The hairline is not asserted; it carries no meaning.
import SwiftUI
import XCTest
@testable import Snag

final class ContrastTests: XCTestCase {
    private func luminance(_ c: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        func f(_ v: CGFloat) -> Double { let v = Double(v); return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
    }

    private func ratio(_ a: Color, _ b: Color) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func assertPairs(_ p: Palette, theme: String) {
        let grounds: [(String, Color)] = [("surface", p.surface), ("raised", p.raised), ("high", p.high)]
            + p.canvas.enumerated().map { ("canvas[\($0.offset)]", $0.element) }
        let text: [(String, Color)] = [("textPrimary", p.textPrimary), ("textSecondary", p.textSecondary)]
        let state: [(String, Color)] = [("accent", p.accent), ("snag", p.snag), ("fine", p.fine), ("altered", p.altered)]
        for (fn, fg) in text {
            for (gn, bg) in grounds {
                XCTAssertGreaterThanOrEqual(ratio(fg, bg), 4.5, "\(theme) \(fn) on \(gn)")
            }
        }
        for (fn, fg) in state {
            for (gn, bg) in grounds {
                XCTAssertGreaterThanOrEqual(ratio(fg, bg), 3.0, "\(theme) \(fn) on \(gn)")
            }
        }
        XCTAssertGreaterThanOrEqual(ratio(p.onAccent, p.accent), 4.5, "\(theme) onAccent on accent")
    }

    func testDarkTheme() { assertPairs(.dark, theme: "dark") }
    func testLightTheme() { assertPairs(.light, theme: "light") }
}
