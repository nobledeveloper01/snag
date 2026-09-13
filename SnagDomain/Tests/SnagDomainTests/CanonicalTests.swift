import Foundation
import Testing
@testable import SnagDomain

/// The report the fixture is made from: two rooms, six items, every optional
/// field exercised at least once. Change nothing here without a new version.
enum Sample {
    static func hash(_ seed: UInt8) -> Hash { (0..<32).map { UInt8(truncatingIfNeeded: Int(seed) &* 31 &+ $0 &* 7) } }

    static var report: Report {
        Report(
            kind: .moveIn, address: "14 Admiralty Way, Lekki Phase 1, Lagos", createdAt: 1_789_000_000,
            movedInReportId: nil,
            rooms: [
                Room(name: .livingRoom, width: Extent(centimetres: 420, tier: .measured), length: Extent(centimetres: 560, tier: .measured),
                     area: Extent(centimetres: 235_200, tier: .measured), planHash: nil,
                     items: [
                        Item(state: .snag, photoHash: hash(1), caption: "Cracked tile below the window", takenAt: 1_789_000_100),
                        Item(state: .fine, photoHash: hash(2), caption: "Balcony door lock", takenAt: 1_789_000_160),
                        Item(state: .snag, photoHash: hash(3), caption: "Damp patch, top left corner — about a palm wide", takenAt: 1_789_000_230),
                     ]),
                Room(name: .other, custom: "Boys' quarters", width: nil, length: nil, area: Extent(centimetres: 90_000, tier: .scanned),
                     planHash: hash(9),
                     items: [
                        Item(state: .fine, photoHash: hash(4), caption: "", takenAt: 1_789_000_400),
                        Item(state: .snag, photoHash: hash(5), caption: "Window latch missing", takenAt: 1_789_000_450),
                        Item(state: .snag, photoHash: hash(6), caption: "Ọmọ — scuff on the door, ₦ mark in pen", takenAt: 1_789_000_500),
                     ]),
            ])
    }

    static var counter: CounterSignature {
        CounterSignature(reportId: hash(42), name: "Mr T. Okafor", phone: "+2348012345678", signatureHash: hash(7), signedAt: 1_789_003_600)
    }
}

@Suite("The canonical encoding")
struct CanonicalTests {
    /// Writes the fixtures from the sample. Run once, with SNAG_WRITE_FIXTURE
    /// set to the Fixtures directory, and commit what it writes. Running it
    /// again overwrites the promise, so it refuses unless the files are absent.
    @Test("Write the fixtures (only when asked, only when absent)")
    func writeFixtures() throws {
        guard let dir = ProcessInfo.processInfo.environment["SNAG_WRITE_FIXTURE"] else { return }
        for (name, bytes) in [("report-v1", try Canonical.bytes(of: Sample.report)),
                              ("countersign-v1", try Canonical.bytes(of: Sample.counter))] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).bin")
            #expect(!FileManager.default.fileExists(atPath: url.path), "\(name).bin exists; a new version needs a new name")
            if !FileManager.default.fileExists(atPath: url.path) { try Data(bytes).write(to: url) }
        }
    }

    private func fixture(_ name: String) throws -> [UInt8] {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "bin", subdirectory: "Fixtures"))
        return Array(try Data(contentsOf: url))
    }

    @Test("The fixture: two rooms, six items, byte for byte. This is Phase 0's exit gate and every signature's promise.")
    func fixtureIsStable() throws {
        let bytes = try Canonical.bytes(of: Sample.report)
        let expected = try fixture("report-v1")
        #expect(bytes == expected, "the encoding changed — every sealed report in the world would read as altered")
        #expect(try Canonical.bytes(of: Sample.counter) == (try fixture("countersign-v1")))
    }

    @Test("Round trip: decode(encode(r)) == r, for the sample and for generated reports")
    func roundTrip() throws {
        #expect(try Canonical.report(from: try Canonical.bytes(of: Sample.report)) == Sample.report)
        #expect(try Canonical.counterSignature(from: try Canonical.bytes(of: Sample.counter)) == Sample.counter)
        var seed: UInt64 = 1
        func next() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed >> 33 }
        for _ in 0..<200 {
            let rooms = (0..<Int(next() % 4)).map { _ -> Room in
                let name = RoomName.allCases[Int(next() % UInt64(RoomName.allCases.count))]
                let items = (0..<Int(next() % 4)).map { _ in
                    Item(state: next() % 2 == 0 ? .snag : .fine, photoHash: Sample.hash(UInt8(next() % 256)),
                         caption: String(repeating: "x", count: Int(next() % 281)), takenAt: Int64(bitPattern: next()))
                }
                let dim = { () -> Extent? in next() % 2 == 0 ? nil : Extent(centimetres: Int32(bitPattern: UInt32(next() % 0xFFFF_FFFF)), tier: Tier.allCases[Int(next() % 3)]) }
                return Room(name: name, custom: name == .other ? "custom \(next())" : nil, width: dim(), length: dim(), area: dim(),
                            planHash: next() % 2 == 0 ? nil : Sample.hash(UInt8(next() % 256)), items: items)
            }
            let r = Report(kind: next() % 2 == 0 ? .moveIn : .moveOut, address: "addr \(next())", createdAt: Int64(bitPattern: next()),
                           movedInReportId: next() % 2 == 0 ? nil : Sample.hash(3), rooms: rooms)
            #expect(try Canonical.report(from: try Canonical.bytes(of: r)) == r)
        }
    }

    @Test("Distinct reports never share bytes")
    func injective() throws {
        var a = Sample.report, b = Sample.report
        b.rooms[1].items[2].caption += "."
        #expect(try Canonical.bytes(of: a) != (try Canonical.bytes(of: b)))
        a.rooms[0].width?.tier = .scanned
        #expect(try Canonical.bytes(of: a) != (try Canonical.bytes(of: Sample.report)))
    }

    @Test("Every truncation is caught, and trailing bytes are refused")
    func truncation() throws {
        let bytes = try Canonical.bytes(of: Sample.report)
        for n in 0..<bytes.count {
            #expect(throws: CanonicalError.self) { try Canonical.report(from: Array(bytes[0..<n])) }
        }
        #expect(throws: CanonicalError.badValue("trailing bytes")) { try Canonical.report(from: bytes + [0]) }
        #expect(throws: CanonicalError.badVersion(2)) { try Canonical.report(from: [2] + bytes.dropFirst()) }
    }

    @Test("A hash is 32 bytes and a caption is at most 280 characters, or it does not encode")
    func limits() {
        var r = Sample.report
        r.rooms[0].items[0].photoHash = [1, 2, 3]
        #expect(throws: CanonicalError.hashNotThirtyTwoBytes) { try Canonical.bytes(of: r) }
        r = Sample.report
        r.rooms[0].items[0].caption = String(repeating: "a", count: 281)
        #expect(throws: CanonicalError.captionTooLong) { try Canonical.bytes(of: r) }
    }

    @Test("The version byte comes first, so a future decoder can tell")
    func versionFirst() throws {
        #expect(try Canonical.bytes(of: Sample.report).first == 1)
        #expect(try Canonical.bytes(of: Sample.counter).first == 1)
    }
}

@Suite("Tiers and counts")
struct TierTests {
    @Test("A room's tier is the highest of its numbers; a report's is the highest of its rooms")
    func tiers() {
        let r = Sample.report
        #expect(r.rooms[0].tier == .measured)
        #expect(r.rooms[1].tier == .scanned)
        #expect(r.tier == .scanned)
        #expect(Room(name: .kitchen).tier == .photographed)
        #expect(Report(kind: .moveIn, address: "", createdAt: 0).tier == .photographed)
    }

    @Test("Counts, and the custom name only for 'other'")
    func counts() {
        #expect(Sample.report.itemCount == 6)
        #expect(Sample.report.snagCount == 4)
        #expect(Room(name: .kitchen, custom: "ignored").custom == nil)
        #expect(Room(name: .other, custom: "Boys' quarters").custom == "Boys' quarters")
    }
}

@Suite("Compare")
struct CompareTests {
    @Test("Same, changed, missing, added — in room and item order")
    func diff() {
        let before = Sample.report
        var after = before
        after.kind = .moveOut
        after.rooms[0].items[1] = Item(state: .snag, photoHash: Sample.hash(99), caption: "Now broken", takenAt: 1)
        after.rooms[0].items.removeLast()                       // one missing in room 0
        after.rooms[1].items.append(Item(state: .snag, photoHash: Sample.hash(100), caption: "New hole", takenAt: 2))
        let d = Compare.diff(movedIn: before, movedOut: after)
        #expect(d == [
            .same(room: 0, item: 0),
            .changed(room: 0, item: 1, from: before.rooms[0].items[1], to: after.rooms[0].items[1]),
            .missing(room: 0, item: before.rooms[0].items[2]),
            .same(room: 1, item: 0), .same(room: 1, item: 1), .same(room: 1, item: 2),
            .added(room: 1, item: after.rooms[1].items[3]),
        ])
    }

    @Test("A move-out with no rooms lists every move-in item as missing; total, never crashes")
    func total() {
        let empty = Report(kind: .moveOut, address: "", createdAt: 0)
        let d = Compare.diff(movedIn: Sample.report, movedOut: empty)
        #expect(d.count == 6)
        #expect(d.allSatisfy { if case .missing = $0 { true } else { false } })
        #expect(Compare.diff(movedIn: empty, movedOut: empty).isEmpty)
    }
}

@Suite("Words")
struct WordTests {
    @Test("Every tier and every room name has a word, and they are distinct")
    func words() {
        #expect(Set(Tier.allCases.map(\.word)).count == 3)
        #expect(Set(RoomName.allCases.map(\.word)).count == RoomName.allCases.count)
        #expect(Tier.scanned.word == "scanned")
        #expect(RoomName.livingRoom.word == "living room")
        #expect(RoomName.other.word == "other")
    }
}
