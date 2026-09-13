// The palette DESIGN.md documents. `make design-check` reads this file and
// fails if the table there disagrees with the constants here, in either
// direction. Every text pair is asserted at 4.5:1 and every state colour at
// 3:1 by SnagTests/ContrastTests, on every ground including both gradient
// stops. The hairline is not asserted; it carries no meaning.
import SwiftUI

struct Palette: Sendable {
    let surface: Color
    let raised: Color
    let high: Color
    let outline: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let onAccent: Color
    let snag: Color
    let fine: Color
    let altered: Color
    let canvas: [Color]

    static let light = Palette(
        surface: Color(hex: 0xFAFBFC), raised: Color(hex: 0xFFFFFF), high: Color(hex: 0xEEF1F5), outline: Color(hex: 0xB9C0CC),
        textPrimary: Color(hex: 0x0F1012), textSecondary: Color(hex: 0x4B5260),
        accent: Color(hex: 0x0B5CAD), onAccent: Color(hex: 0xFFFFFF),
        snag: Color(hex: 0x8A4300), fine: Color(hex: 0x1E7A3E), altered: Color(hex: 0xB3261E),
        canvas: [Color(hex: 0xFAFBFC), Color(hex: 0xF1F4F8)]
    )

    static let dark = Palette(
        surface: Color(hex: 0x0F1012), raised: Color(hex: 0x1A1C20), high: Color(hex: 0x25282E), outline: Color(hex: 0x454A54),
        textPrimary: Color(hex: 0xF2F4F7), textSecondary: Color(hex: 0xA7ADB8),
        accent: Color(hex: 0x5AB0FF), onAccent: Color(hex: 0x06101C),
        snag: Color(hex: 0xFFA24A), fine: Color(hex: 0x63D68A), altered: Color(hex: 0xFF7B7B),
        canvas: [Color(hex: 0x161A20), Color(hex: 0x0F1012)]
    )

    /// Dark is the default, not the system setting. Both are authored.
    static func current(_ scheme: ColorScheme) -> Palette { scheme == .light ? .light : .dark }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
