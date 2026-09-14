// Inter, bundled — one variable file, every weight — as in every
// cross-platform project in the portfolio, because the report's PDF is set
// in the same face as the app. Every size is relative to a text style so
// Dynamic Type scales it. `make design-check` reads the constants.
import SwiftUI

enum Type {
    static let display: CGFloat = 22
    static let headline: CGFloat = 18
    static let title: CGFloat = 17
    static let body: CGFloat = 15
    static let secondary: CGFloat = 14
    static let small: CGFloat = 13

    // The PostScript name of the bundled variable font, which is what both
    // UIFont and Font.custom resolve; the family name is "Inter Variable"
    // and neither API takes it. Proved by `TypeTests`: a wrong name here
    // falls back to the system face without a word.
    static let family = "InterVariable"

    static func displayFont() -> Font { .custom(family, size: display, relativeTo: .title2).weight(.bold) }
    static func headlineFont() -> Font { .custom(family, size: headline, relativeTo: .headline).weight(.semibold) }
    static func titleFont() -> Font { .custom(family, size: title, relativeTo: .body).weight(.semibold) }
    static func bodyFont() -> Font { .custom(family, size: body, relativeTo: .body) }
    static func secondaryFont() -> Font { .custom(family, size: secondary, relativeTo: .subheadline) }
    static func smallFont() -> Font { .custom(family, size: small, relativeTo: .footnote).weight(.medium) }
}
