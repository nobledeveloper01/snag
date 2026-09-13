// Targets, radii and the spacing grid. DESIGN.md is the authority and
// `make design-check` holds the two together.
import CoreGraphics

enum Target {
    static let standard: CGFloat = 56
    static let primary: CGFloat = 64     // the shutter and Next room, pressed at arm's length
}

enum Radius {
    static let tile: CGFloat = 16
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

enum Gap {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let sm: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}
