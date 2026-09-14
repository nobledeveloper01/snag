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
        let image = Data((0..<900).map { UInt8(truncatingIfNeeded: $0 * 5) })
        let c = CounterSignature(reportId: id, name: "Mr Okafor", phone: "+2348012345678", signatureHash: SnagBundle.sha256(image), signedAt: 9)
        let cBytes = try Canonical.bytes(of: c)
        try SnagBundle.writeCounterSignature(cBytes, seal: try sealer.seal(cBytes), signature: image, to: b)
        guard case .unaltered(_, let counter) = Verifier.verify(b), counter == c else { return XCTFail("counter-signature did not verify") }
        // The drawn signature swapped for another: altered.
        try Data(image.reversed()).write(to: b.appendingPathComponent(SnagBundle.signatureImage))
        guard case .altered("signature image") = Verifier.verify(b) else { return XCTFail("a swapped signature image was accepted") }
        try image.write(to: b.appendingPathComponent(SnagBundle.signatureImage))
        // The same signed layer, pointed at a different report id: altered.
        let other = CounterSignature(reportId: [UInt8](repeating: 1, count: 32), name: c.name, phone: c.phone, signatureHash: c.signatureHash, signedAt: c.signedAt)
        let oBytes = try Canonical.bytes(of: other)
        try SnagBundle.writeCounterSignature(oBytes, seal: try sealer.seal(oBytes), signature: image, to: b)
        guard case .altered("counter-signature is for another report") = Verifier.verify(b) else { return XCTFail("a moved counter-signature was accepted") }
    }

    /// Writes `SnagTests/Fixtures/bundle-v1`: a sealed bundle with a
    /// counter-signature, made by the app's own sealer, for the Python
    /// verifier in `scripts/verify.py` to be checked against in CI. Run once:
    ///   TEST_RUNNER_SNAG_WRITE_BUNDLE_FIXTURE=<abs path to SnagTests/Fixtures/bundle-v1> make test-app
    /// Refuses to overwrite: a new fixture is a decision, not a side effect.
    func testWriteBundleFixture() throws {
        guard let path = ProcessInfo.processInfo.environment["SNAG_WRITE_BUNDLE_FIXTURE"] else { throw XCTSkip("SNAG_WRITE_BUNDLE_FIXTURE not set") }
        let target = URL(fileURLWithPath: path)
        guard !FileManager.default.fileExists(atPath: target.path) else { throw XCTSkip("fixture exists; delete it on purpose first") }
        let (r, _) = try sealedBundle()
        let b = dir.appendingPathComponent("b.snag")
        let id = SnagBundle.sha256(Data(try Canonical.bytes(of: r)))
        let image = Data((0..<900).map { UInt8(truncatingIfNeeded: $0 * 5) })
        let c = CounterSignature(reportId: id, name: "Mr T. Okafor", phone: "+2348012345678", signatureHash: SnagBundle.sha256(image), signedAt: 1_789_003_600)
        let cBytes = try Canonical.bytes(of: c)
        try SnagBundle.writeCounterSignature(cBytes, seal: try sealer.seal(cBytes), signature: image, to: b)
        // And an amendment: the kitchen scanned later, its plan in the bundle.
        var amended = r
        XCTAssertTrue(amended.rooms[1].measure(ScannedFloor.fixture.corners, tier: .scanned))
        let plan = try XCTUnwrap(PlanRenderer.jpeg(ScannedFloor.fixture, label: "Kitchen"))
        let planURL = dir.appendingPathComponent("plan.jpg"); try plan.write(to: planURL)
        amended.rooms[1].planHash = SnagBundle.sha256(plan)
        let aBytes = try Canonical.bytes(of: Amendment(originalId: id, amendedAt: 1_789_090_000, report: amended))
        try SnagBundle.writeAmendment(aBytes, seal: try sealer.seal(aBytes), photos: [(SnagBundle.sha256(plan), planURL)], to: b)
        guard case .unaltered(let shown, _) = Verifier.verify(b), shown == amended else { return XCTFail("the fixture must verify, amended, before it is written") }
        try FileManager.default.copyItem(at: b, to: target)
    }

    func testAnAmendmentAddsNumbersUnderTheSameKeyAndNothingElse() throws {
        let (r, _) = try sealedBundle()
        let b = dir.appendingPathComponent("b.snag")
        let id = SnagBundle.sha256(Data(try Canonical.bytes(of: r)))
        var amended = r
        XCTAssertTrue(amended.rooms[1].measure(ScannedFloor.fixture.corners, tier: .scanned))
        let plan = try XCTUnwrap(PlanRenderer.jpeg(ScannedFloor.fixture, label: "Kitchen"))
        let planURL = dir.appendingPathComponent("plan.jpg"); try plan.write(to: planURL)
        amended.rooms[1].planHash = SnagBundle.sha256(plan)
        let aBytes = try Canonical.bytes(of: Amendment(originalId: id, amendedAt: 9, report: amended))
        try SnagBundle.writeAmendment(aBytes, seal: try sealer.seal(aBytes), photos: [(SnagBundle.sha256(plan), planURL)], to: b)
        guard case .unaltered(let shown, _) = Verifier.verify(b) else { return XCTFail("the amended bundle verifies") }
        XCTAssertEqual(shown, amended, "the amended report is the one shown")
        XCTAssertEqual(shown.tier, .scanned)
        XCTAssertEqual(Verifier.amendment(in: b)?.amendedAt, 9)
        // The original's seal still stands on its own bytes.
        let original = try Canonical.report(from: Array(try Data(contentsOf: b.appendingPathComponent(SnagBundle.reportFile))))
        XCTAssertEqual(original, r)
        // An amendment that changes a caption: altered.
        var reworded = amended
        reworded.rooms[0].items[0].caption = "Not what was written"
        let wBytes = try Canonical.bytes(of: Amendment(originalId: id, amendedAt: 9, report: reworded))
        try SnagBundle.writeAmendment(wBytes, seal: try sealer.seal(wBytes), photos: [], to: b)
        guard case .altered("amendment changes more than numbers") = Verifier.verify(b) else { return XCTFail("a reworded amendment was accepted") }
        // An amendment for another report: altered.
        let oBytes = try Canonical.bytes(of: Amendment(originalId: [UInt8](repeating: 3, count: 32), amendedAt: 9, report: amended))
        try SnagBundle.writeAmendment(oBytes, seal: try sealer.seal(oBytes), photos: [], to: b)
        guard case .altered("amendment is for another report") = Verifier.verify(b) else { return XCTFail("a moved amendment was accepted") }
        // Every byte of a good amendment flipped: altered.
        try SnagBundle.writeAmendment(aBytes, seal: try sealer.seal(aBytes), photos: [], to: b)
        let good = try Data(contentsOf: b.appendingPathComponent(SnagBundle.amendmentFile))
        for i in stride(from: 0, to: good.count, by: max(1, good.count / 40)) {
            var bad = good; bad[i] ^= 0x01
            try bad.write(to: b.appendingPathComponent(SnagBundle.amendmentFile))
            if case .unaltered = Verifier.verify(b) { XCTFail("amendment byte \(i) flipped and accepted") }
        }
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
