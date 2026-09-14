import Testing
@testable import SnagDomain

@Suite("The floor")
struct FloorTests {
    let rect = [Corner(x: 0, y: 0), Corner(x: 4, y: 0), Corner(x: 4, y: 5), Corner(x: 0, y: 5)]

    @Test("a 4 by 5 rectangle is 20 square metres, 4 wide and 5 long")
    func rectangle() {
        #expect(Floor.area(rect) == 20)
        let s = Floor.sides(rect)!
        #expect(abs(s.width - 4) < 1e-9 && abs(s.length - 5) < 1e-9)
        let e = Floor.extents(rect, tier: .measured)!
        #expect(e.width.centimetres == 400 && e.length.centimetres == 500 && e.area.centimetres == 200_000)
        #expect(e.width.tier == .measured && e.area.tier == .measured)
    }

    @Test("the order of the corners does not change the area, and neither does where the room is or how it is turned")
    func invariance() {
        #expect(Floor.area(rect.reversed()) == 20)
        let moved = rect.map { Corner(x: $0.x + 12.5, y: $0.y - 3) }
        #expect(abs(Floor.area(moved)! - 20) < 1e-9)
        let t = 0.7
        let turned = rect.map { Corner(x: $0.x * _cos(t) - $0.y * _sin(t), y: $0.x * _sin(t) + $0.y * _cos(t)) }
        #expect(abs(Floor.area(turned)! - 20) < 1e-6)
        let s = Floor.sides(turned)!
        #expect(abs(s.width - 4) < 1e-6 && abs(s.length - 5) < 1e-6, "sides follow the longest edge, not the axes")
    }

    @Test("an L-shaped room measures its own area and the rectangle it sits in")
    func lShape() {
        let l = [Corner(x: 0, y: 0), Corner(x: 6, y: 0), Corner(x: 6, y: 2), Corner(x: 2, y: 2), Corner(x: 2, y: 4), Corner(x: 0, y: 4)]
        #expect(Floor.area(l) == 16.0)
        let s = Floor.sides(l)!
        #expect(abs(s.width - 4) < 1e-9 && abs(s.length - 6) < 1e-9)
    }

    @Test("two corners are a line, a zero-area shape is nothing, and photographed is not a measurement")
    func refusals() {
        #expect(Floor.area([Corner(x: 0, y: 0), Corner(x: 3, y: 0)]) == nil)
        #expect(Floor.area([Corner(x: 0, y: 0), Corner(x: 3, y: 0), Corner(x: 6, y: 0)]) == nil)
        #expect(Floor.extents(rect, tier: .photographed) == nil)
    }

    @Test("a room takes a measurement, keeps a scan over a measurement, and never the other way")
    func roomTier() {
        var room = Room(name: .kitchen)
        #expect(room.tier == .photographed)
        let measured = room.measure(rect, tier: .measured)
        #expect(measured)
        #expect(room.tier == .measured && room.area?.centimetres == 200_000)
        let scanned = room.measure(rect.map { Corner(x: $0.x * 1.1, y: $0.y) }, tier: .scanned)
        #expect(scanned)
        #expect(room.tier == .scanned && room.width?.centimetres == 440)
        let downgraded = room.measure(rect, tier: .measured)
        #expect(!downgraded, "a scan is not overwritten by a tap")
        #expect(room.width?.centimetres == 440)
        let nothing = room.measure([Corner(x: 0, y: 0)], tier: .scanned)
        #expect(!nothing)
    }
}

// The domain has no Foundation, so the test brings its own trigonometry.
private func _sin(_ x: Double) -> Double { var t = x, s = 0.0; for n in 0..<12 { s += t; t *= -x * x / Double((2 * n + 2) * (2 * n + 3)) }; return s }
private func _cos(_ x: Double) -> Double { var t = 1.0, s = 0.0; for n in 0..<12 { s += t; t *= -x * x / Double((2 * n + 1) * (2 * n + 2)) }; return s }
