// The mirror, against a cloud in memory: two phones, one Apple ID.
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class CloudTests: XCTestCase {
    private func store() -> ReportStore { ReportStore(root: FileManager.default.temporaryDirectory.appendingPathComponent("cloud-\(UUID().uuidString)")) }

    private func seal(_ store: ReportStore, _ address: String) throws -> ReportStore.Sealed {
        var d = store.newDraft(kind: .moveIn, address: address, now: 1_789_000_000)
        let photo = try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "fixture-3", withExtension: "jpg")))
        let h = store.store(photo: photo, in: d)
        d.report.rooms = [Room(name: .bedroom, items: [Item(state: .fine, photoHash: h, caption: address, takenAt: 1)])]
        store.update(d)
        return try store.seal(d, with: try Sealer())
    }

    func testTwoPhonesMeetInTheCloudAndATamperedBundleIsRefused() async throws {
        let cloud = MemoryCloud()
        let a = store(), b = store()
        let first = try seal(a, "1 Cloud Way")
        _ = try seal(a, "2 Cloud Way")
        let up = try await CloudMirror.sync(a, with: cloud)
        XCTAssertEqual(up, .init(pushed: 2, pulled: 0, refused: 0))
        let again = try await CloudMirror.sync(a, with: cloud)
        XCTAssertEqual(again, .init(), "nothing moves twice")
        let down = try await CloudMirror.sync(b, with: cloud)
        XCTAssertEqual(down, .init(pushed: 0, pulled: 2, refused: 0))
        XCTAssertEqual(b.sealed.map(\.report.address).sorted(), ["1 Cloud Way", "2 Cloud Way"])
        for s in b.sealed { guard case .unaltered = Verifier.verify(s.url) else { return XCTFail("a pulled bundle verifies") } }

        // A counter-signature on phone A is a new layer: up, then down to B.
        let image = Data((0..<500).map { UInt8($0 & 0xff) })
        _ = try a.counterSign(first, name: "Mr Okafor", phone: "0801", signature: image, with: try Sealer(), now: 5)
        let upLayer = try await CloudMirror.sync(a, with: cloud)
        XCTAssertEqual(upLayer, .init(pushed: 1, pulled: 0, refused: 0))
        let downLayer = try await CloudMirror.sync(b, with: cloud)
        XCTAssertEqual(downLayer, .init(pushed: 0, pulled: 1, refused: 0))
        XCTAssertEqual(b.sealed.first { $0.id == first.id }?.counter?.name, "Mr Okafor")

        // A tampered file in the cloud, claiming a layer B lacks: refused, and B keeps its own.
        var bytes = try ZipFile.archive(directory: first.url)
        let idx = try XCTUnwrap(bytes.range(of: Data("report.bin".utf8))?.upperBound) + 5
        bytes[idx] ^= 0x01
        await cloud.overwrite(first.id, layers: "ac", data: bytes)
        let c = store()
        let refused = try await CloudMirror.sync(c, with: cloud)
        XCTAssertEqual(refused.refused, 1)
        XCTAssertEqual(refused.pulled, 1, "the untouched one still comes down")
        XCTAssertEqual(c.sealed.count, 1)
    }
}
