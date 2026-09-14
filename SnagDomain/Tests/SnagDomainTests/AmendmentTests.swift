import Testing
@testable import SnagDomain

@Suite("The amendment layer")
struct AmendmentTests {
    @Test("an amendment round-trips, and its first byte is its version")
    func roundTrip() throws {
        var amended = Sample.report
        _ = amended.rooms[1].measure([Corner(x: 0, y: 0), Corner(x: 3, y: 0), Corner(x: 3, y: 3), Corner(x: 0, y: 3)], tier: .scanned)
        let a = Amendment(originalId: Sample.hash(42), amendedAt: 1_800_000_000, report: amended)
        let bytes = try Canonical.bytes(of: a)
        #expect(bytes[0] == 1)
        #expect(Array(bytes[1..<33]) == Sample.hash(42))
        #expect(try Canonical.amendment(from: bytes) == a)
        #expect(throws: CanonicalError.self) { try Canonical.amendment(from: Array(bytes.prefix(20))) }
        #expect(throws: CanonicalError.self) { try Canonical.amendment(from: [2] + bytes.dropFirst()) }
        #expect(throws: CanonicalError.self) { try Canonical.bytes(of: Amendment(originalId: [1, 2, 3], amendedAt: 0, report: amended)) }
    }

    @Test("the original encoding is untouched by the layer: the fixture bytes are the report's own")
    func originalUntouched() throws {
        let a = Amendment(originalId: Sample.hash(1), amendedAt: -5, report: Sample.report)
        let bytes = try Canonical.bytes(of: a)
        #expect(Array(bytes[41...]) == (try Canonical.bytes(of: Sample.report)))
        #expect(try Canonical.amendment(from: bytes).amendedAt == -5, "a negative date survives the round trip")
    }

    @Test("an amendment may raise a room's numbers and nothing else")
    func onlyNumbers() {
        let original = Sample.report
        var scanned = original
        _ = scanned.rooms[0].measure([Corner(x: 0, y: 0), Corner(x: 4, y: 0), Corner(x: 4, y: 5), Corner(x: 0, y: 5)], tier: .scanned)
        #expect(scanned.amendsOnlyNumbers(of: original))
        var recaptioned = original
        recaptioned.rooms[0].items[0].caption = "Something else"
        #expect(!recaptioned.amendsOnlyNumbers(of: original))
        var lowered = original
        lowered.rooms[0].width = nil; lowered.rooms[0].length = nil; lowered.rooms[0].area = nil
        #expect(!lowered.amendsOnlyNumbers(of: original), "a photographed room cannot amend a measured one")
        var moved = original
        moved.address = "Elsewhere"
        #expect(!moved.amendsOnlyNumbers(of: original))
        #expect(original.amendsOnlyNumbers(of: original), "no change is a lawful amendment, if a pointless one")
    }
}
