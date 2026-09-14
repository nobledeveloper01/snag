// The floor plan as a picture, and a scanned room sealed and verified with
// its plan in the bundle — the whole scanned tier short of the sensor.
import PDFKit
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class PlanTests: XCTestCase {
    func testTheFixtureFloorDrawsAPlanOfTheRightSizeWithItsNumbers() throws {
        let data = try XCTUnwrap(PlanRenderer.jpeg(ScannedFloor.fixture, label: "Kitchen"))
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(image.size, PlanRenderer.size)
        XCTAssertEqual(Photo.judge(data), [], "a plan is neither dark nor blurred")
        let e = try XCTUnwrap(Floor.extents(ScannedFloor.fixture.corners, tier: .scanned))
        XCTAssertEqual((e.width.centimetres, e.length.centimetres, e.area.centimetres).0, 360)
        XCTAssertEqual(e.length.centimetres, 420)
        XCTAssertEqual(e.area.centimetres, 151_200)
        XCTAssertEqual(Dimensions.line(e.width, e.length, e.area), "3.60 × 4.20 m · 15.1 m²")
        XCTAssertNil(PlanRenderer.jpeg(ScannedFloor(corners: [], walls: [], openings: []), label: ""), "no corners, no plan")
    }

    func testAScannedRoomSealsWithItsPlanAndTheVerifierChecksThePlanToo() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("plan-\(UUID().uuidString)")
        let store = ReportStore(root: root)
        var d = store.newDraft(kind: .moveIn, address: "2 Plan Close", now: 1_789_000_000, template: .selfContain)
        let photo = try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "fixture-1", withExtension: "jpg")))
        let h = store.store(photo: photo, in: d)
        d.report.rooms[0].items = [Item(state: .fine, photoHash: h, caption: "", takenAt: 1)]
        XCTAssertTrue(d.report.rooms[0].measure(ScannedFloor.tappedFixture, tier: .measured))
        XCTAssertEqual(d.report.tier, .measured)
        XCTAssertTrue(d.report.rooms[0].measure(ScannedFloor.fixture.corners, tier: .scanned))
        let plan = try XCTUnwrap(PlanRenderer.jpeg(ScannedFloor.fixture, label: "Living room"))
        d.report.rooms[0].planHash = store.store(photo: plan, in: d)
        store.update(d)
        XCTAssertEqual(d.report.tier, .scanned)
        let sealed = try store.seal(d, with: try Sealer())
        guard case .unaltered(let r, _) = Verifier.verify(sealed.url) else { return XCTFail("a scanned room's bundle verifies") }
        XCTAssertEqual(r.rooms[0].planHash, d.report.rooms[0].planHash)
        XCTAssertTrue(FileManager.default.fileExists(atPath: SnagBundle.photoURL(in: sealed.url, hash: r.rooms[0].planHash!).path), "the plan travels in the bundle by its hash")
        // The plan swapped for the photograph: altered, because the plan is named by its hash like any picture.
        try photo.write(to: SnagBundle.photoURL(in: sealed.url, hash: r.rooms[0].planHash!))
        guard case .altered = Verifier.verify(sealed.url) else { return XCTFail("a swapped plan was accepted") }
        try? FileManager.default.removeItem(at: root)
    }

    func testThePDFDrawsThePlanOnTheRoomPage() throws {
        let plan = try XCTUnwrap(PlanRenderer.jpeg(ScannedFloor.fixture, label: "Kitchen"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("plan-\(UUID().uuidString).jpg")
        try plan.write(to: url)
        let hash = SnagBundle.sha256(plan)
        var room = Room(name: .kitchen)
        XCTAssertTrue(room.measure(ScannedFloor.fixture.corners, tier: .scanned))
        room.planHash = hash
        let report = Report(kind: .moveIn, address: "2 Plan Close", createdAt: 1_789_000_000, rooms: [room])
        let data = ReportPDF.render(report, id: String(repeating: "ef", count: 32), publicKey: [UInt8](repeating: 4, count: 65)) { h in h == hash ? url : URL(fileURLWithPath: "/nonexistent.jpg") }
        let pdf = try XCTUnwrap(PDFDocument(data: data))
        let page = try XCTUnwrap(pdf.page(at: 1)?.string?.replacingOccurrences(of: "\n", with: " "))
        XCTAssertTrue(page.contains("Kitchen") && page.contains("scanned") && page.contains("3.60") && page.contains("4.20 m") && page.contains("Floor plan"), page)
        XCTAssertTrue(try XCTUnwrap(pdf.page(at: 0)?.string).contains("scanned"), "the cover's tier is the highest in the report")
    }
}
