// A floor as the corners the tenant tapped or the scanner found, in metres
// on the floor's own plane, and the three numbers the report keeps from it:
// width, length, area — in whole centimetres, each with the tier it came
// from. Pure arithmetic, so the same code serves ARKit corners, a RoomPlan
// polygon, and a fixture on the simulator, and a wrong number here is a
// test failure and not a tenant's problem.

public struct Corner: Sendable, Equatable {
    public var x: Double     // metres
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public enum Floor {
    /// Square metres of the polygon, by the shoelace formula. Nil for fewer
    /// than three corners — two taps are a line, not a floor.
    public static func area(_ corners: [Corner]) -> Double? {
        guard corners.count >= 3 else { return nil }
        var twice = 0.0
        for i in corners.indices {
            let a = corners[i], b = corners[(i + 1) % corners.count]
            twice += a.x * b.y - b.x * a.y
        }
        let area = (twice < 0 ? -twice : twice) / 2
        return area > 0 ? area : nil
    }

    /// Width and length: the sides of the tightest rectangle aligned with
    /// the polygon's longest edge, so a room tapped at a slant measures the
    /// same as one tapped square. Length is the longer of the two.
    public static func sides(_ corners: [Corner]) -> (width: Double, length: Double)? {
        guard corners.count >= 3 else { return nil }
        var longest = (0.0, Corner(x: 1, y: 0))
        for i in corners.indices {
            let a = corners[i], b = corners[(i + 1) % corners.count]
            let d = Corner(x: b.x - a.x, y: b.y - a.y)
            let len = (d.x * d.x + d.y * d.y).squareRoot()
            if len > longest.0 { longest = (len, Corner(x: d.x / len, y: d.y / len)) }
        }
        guard longest.0 > 0 else { return nil }
        let u = longest.1, v = Corner(x: -u.y, y: u.x)
        var minU = Double.infinity, maxU = -Double.infinity, minV = Double.infinity, maxV = -Double.infinity
        for c in corners {
            let pu = c.x * u.x + c.y * u.y, pv = c.x * v.x + c.y * v.y
            minU = min(minU, pu); maxU = max(maxU, pu); minV = min(minV, pv); maxV = max(maxV, pv)
        }
        let a = maxU - minU, b = maxV - minV
        guard a > 0, b > 0 else { return nil }
        return (min(a, b), max(a, b))
    }

    /// The three extents the room keeps, rounded to the centimetre, with
    /// the tier they were made at. Nil when the corners make no floor.
    public static func extents(_ corners: [Corner], tier: Tier) -> (width: Extent, length: Extent, area: Extent)? {
        guard tier != .photographed, let a = area(corners), let s = sides(corners) else { return nil }
        return (Extent(centimetres: cm(s.width), tier: tier), Extent(centimetres: cm(s.length), tier: tier), Extent(centimetres: cm2(a), tier: tier))
    }

    static func cm(_ metres: Double) -> Int32 { Int32((metres * 100).rounded()) }
    static func cm2(_ squareMetres: Double) -> Int32 { Int32((squareMetres * 10_000).rounded()) }
}

extension Room {
    /// Measured or scanned: the three numbers set at once, never one without
    /// the others, and never a lower tier over a higher one.
    public mutating func measure(_ corners: [Corner], tier: Tier) -> Bool {
        guard let e = Floor.extents(corners, tier: tier), tier.rawValue >= self.tier.rawValue else { return false }
        width = e.width; length = e.length; area = e.area
        return true
    }
}
