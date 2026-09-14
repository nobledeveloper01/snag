// The PDF is a rendering of the sealed bytes: one page per room, the tier
// word beside every room, and a last page that says what the report is.
import PDFKit
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class PDFTests: XCTestCase {
    func testOnePagePerRoomAndTheLastPageSaysWhatTheReportIs() throws {
        let report = Report(kind: .moveIn, address: "14 Admiralty Way", createdAt: 1_789_000_000, rooms: [
            Room(name: .kitchen, items: [Item(state: .snag, photoHash: Array(repeating: 1, count: 32), caption: "Cracked tile", takenAt: 1_789_000_100)]),
            Room(name: .bedroom, width: Extent(centimetres: 320, tier: .measured), length: Extent(centimetres: 410, tier: .measured)),
        ])
        let data = ReportPDF.render(report, id: String(repeating: "ab", count: 32)) { _ in URL(fileURLWithPath: "/nonexistent.jpg") }
        let pdf = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertEqual(pdf.pageCount, 4, "cover, two rooms, the last page")
        let text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }
        XCTAssertTrue(text[1].contains("Kitchen") && text[1].contains("photographed"))
        XCTAssertTrue(text[2].contains("Bedroom") && text[2].contains("measured") && text[2].contains("320 × 410 cm"), "the tier is beside the number")
        XCTAssertTrue(text[3].contains(ReportText.whatThisIs))
        for para in ReportText.whatThisIsBody { XCTAssertTrue(text[3].replacingOccurrences(of: "\n", with: " ").contains(String(para.prefix(40))), "last page carries: \(para.prefix(40))") }
        XCTAssertTrue(text[0].contains("abababab") && text[3].contains("abababab"), "the report id is on the cover and the last page")
    }
}
