// The verifier, proved against a tampered bundle — every byte of every file
// flipped in turn — because a verifier that has never seen a tampered file
// is one nobody knows the behaviour of. Phase 1's exit gate.
import CryptoKit
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class VerifierTests: XCTestCase {
    private var dir: URL!
    private var sealer: Sealer!

    override func setUp() async throws {
        Sealer.reset()
        sealer = try Sealer()
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("snag-verify-\(UUID().uuidString)")
    }

    override func tearDown() async throws { try? FileManager.default.removeItem(at: dir) }

    /// A report whose photographs exist: three synthetic JPEG-ish files, each
    /// hashed, each named in the report by that hash.
    private func sealedBundle() throws -> (Report, [([UInt8], URL)]) {
        let photosSrc = dir.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: photosSrc, withIntermediateDirectories: true)
        var photos: [([UInt8], URL)] = []
        for i in 0..<3 {
            let data = Data((0..<600).map { UInt8(truncatingIfNeeded: $0 * (i + 3)) })
            let h = SnagBundle.sha256(data)
            let url = photosSrc.appendingPathComponent("p\(i).jpg")
            try data.write(to: url)
            photos.append((h, url))
        }
        var r = Report(kind: .moveIn, address: "14 Admiralty Way", createdAt: 1_789_000_000)
        r.rooms = [
            Room(name: .livingRoom, width: Extent(centimetres: 420, tier: .measured), items: [
                Item(state: .snag, photoHash: photos[0].0, caption: "Cracked tile", takenAt: 1),
                Item(state: .fine, photoHash: photos[1].0, caption: "", takenAt: 2),
            ]),
            Room(name: .kitchen, items: [Item(state: .snag, photoHash: photos[2].0, caption: "Tap drips", takenAt: 3)]),
        ]
        let bytes = try Canonical.bytes(of: r)
        let seal = try sealer.seal(bytes)
        try SnagBundle.write(report: bytes, seal: seal, photos: photos, to: dir.appendingPathComponent("b.snag"))
        return (r, photos)
    }

    func testASealedBundleVerifiesUnaltered() throws {
        let (r, _) = try sealedBundle()
        guard case .unaltered(let decoded, let counter) = Verifier.verify(dir.appendingPathComponent("b.snag")) else { return XCTFail("did not verify") }
        XCTAssertEqual(decoded, r)
        XCTAssertNil(counter)
    }

    func testEveryFlippedByteOfEveryFileIsAltered() throws {
        _ = try sealedBundle()
        let b = dir.appendingPathComponent("b.snag")
        let files = [SnagBundle.reportFile, SnagBundle.signatureFile, SnagBundle.keyFile] + (try FileManager.default.contentsOfDirectory(atPath: b.appendingPathComponent("photos").path)).map { "photos/\($0)" }
        var flips = 0
        for f in files {
            let url = b.appendingPathComponent(f)
            let original = try Data(contentsOf: url)
            for i in 0..<original.count {
                var t = original; t[i] ^= 0x01
                try t.write(to: url)
                if case .unaltered = Verifier.verify(b) { XCTFail("\(f) byte \(i) flipped and still unaltered") }
                flips += 1
            }
            try original.write(to: url)
        }
        XCTAssertGreaterThan(flips, 1500, "the whole bundle was flipped, byte by byte")
        guard case .unaltered = Verifier.verify(b) else { return XCTFail("restored bundle should verify") }
    }

    func testAMissingOrStrayPhotographIsAltered() throws {
        _ = try sealedBundle()
        let b = dir.appendingPathComponent("b.snag"), photos = b.appendingPathComponent("photos")
        let one = try FileManager.default.contentsOfDirectory(atPath: photos.path).first!
        let keep = try Data(contentsOf: photos.appendingPathComponent(one))
        try FileManager.default.removeItem(at: photos.appendingPathComponent(one))
        guard case .altered(let why) = Verifier.verify(b), why.hasPrefix("photo missing") else { return XCTFail("missing photo not caught") }
        try keep.write(to: photos.appendingPathComponent(one))
        try Data([1, 2, 3]).write(to: photos.appendingPathComponent(String(repeating: "ab", count: 32) + ".jpg"))
        guard case .altered("stray photo") = Verifier.verify(b) else { return XCTFail("stray photo not caught") }
    }

    func testACounterSignatureVerifiesAndCannotBeMovedToAnotherReport() throws {
        let (r, _) = try sealedBundle()
        let b = dir.appendingPathComponent("b.snag")
        let id = SnagBundle.sha256(Data(try Canonical.bytes(of: r)))
        let c = CounterSignature(reportId: id, name: "Mr Okafor", phone: "+2348012345678", signatureHash: [UInt8](repeating: 7, count: 32), signedAt: 9)
        let cBytes = try Canonical.bytes(of: c)
        try SnagBundle.writeCounterSignature(cBytes, seal: try sealer.seal(cBytes), to: b)
        guard case .unaltered(_, let counter) = Verifier.verify(b), counter == c else { return XCTFail("counter-signature did not verify") }
        // The same signed layer, pointed at a different report id: altered.
        let other = CounterSignature(reportId: [UInt8](repeating: 1, count: 32), name: c.name, phone: c.phone, signatureHash: c.signatureHash, signedAt: c.signedAt)
        let oBytes = try Canonical.bytes(of: other)
        try SnagBundle.writeCounterSignature(oBytes, seal: try sealer.seal(oBytes), to: b)
        guard case .altered("counter-signature is for another report") = Verifier.verify(b) else { return XCTFail("a moved counter-signature was accepted") }
    }

    func testNotABundle() {
        XCTAssertEqual(Verifier.verify(dir.appendingPathComponent("nothing")), .notABundle)
    }

    func testTheKeyPersistsAcrossSealers() throws {
        let first = sealer.publicKey
        XCTAssertEqual(try Sealer().publicKey, first, "the same key, so a second seal verifies with the first bundle's key")
        Sealer.reset()
        XCTAssertNotEqual(try Sealer().publicKey, first, "after a reset, a new key")
    }
}
