// The PDF is a rendering of the sealed bytes: one page per room, the tier
// word beside every room, and a last page that says what the report is.
import CoreImage
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
        let key = [UInt8](repeating: 4, count: 65)
        let data = ReportPDF.render(report, id: String(repeating: "ab", count: 32), publicKey: key) { _ in URL(fileURLWithPath: "/nonexistent.jpg") }
        let pdf = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertEqual(pdf.pageCount, 5, "cover, two rooms, the contact sheet, the last page")
        let text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string?.replacingOccurrences(of: "\n", with: " ") }
        XCTAssertTrue(text[0].contains("Kitchen") && text[0].contains("Bedroom") && text[0].contains("measured"), "the cover's table names every room with its tier")
        XCTAssertTrue(text[0].contains("Walked in 0 minutes"), "the timeline is on the cover")
        XCTAssertTrue(text[1].contains("Kitchen") && text[1].contains("photographed"))
        XCTAssertTrue(text[2].contains("Bedroom") && text[2].contains("measured") && text[2].contains("320") && text[2].contains("410"), "the tier is beside the number — \(text[2])")
        XCTAssertTrue(text[3].contains(ReportText.contactSheet) && text[3].contains("010101010101"), "the contact sheet carries the hash prefix")
        XCTAssertTrue(text[4].contains(ReportText.whatThisIs))
        for para in ReportText.whatThisIsBody { XCTAssertTrue(text[4].contains(String(para.prefix(40))), "last page carries: \(para.prefix(40))") }
        XCTAssertTrue(text[0].contains("abababab") && text[4].contains("abababab"), "the report id is on the cover and the last page")
        for (i, t) in text.enumerated() { XCTAssertTrue(t.contains("Page \(i + 1) of 5"), "page \(i + 1) is numbered") }
        for t in text { XCTAssertTrue(t.contains("14 Admiralty Way"), "every page carries the address") }
    }

    func testAMoveOutWithAMoveInAndASignatureGetsTheirPages() throws {
        let movedIn = Report(kind: .moveIn, address: "14 Admiralty Way", createdAt: 1_789_000_000, rooms: [
            Room(name: .kitchen, items: [Item(state: .snag, photoHash: Array(repeating: 1, count: 32), caption: "Cracked tile", takenAt: 1_789_000_100),
                                         Item(state: .fine, photoHash: Array(repeating: 2, count: 32), caption: "Tap", takenAt: 1_789_000_110)]),
        ])
        let movedOut = Report(kind: .moveOut, address: "14 Admiralty Way", createdAt: 1_820_000_000, movedInReportId: Array(repeating: 9, count: 32), rooms: [
            Room(name: .kitchen, items: [Item(state: .snag, photoHash: Array(repeating: 1, count: 32), caption: "Cracked tile", takenAt: 1_820_000_100),
                                         Item(state: .snag, photoHash: Array(repeating: 3, count: 32), caption: "Tap", takenAt: 1_820_000_110),
                                         Item(state: .snag, photoHash: Array(repeating: 4, count: 32), caption: "Burn on the hob", takenAt: 1_820_000_120)]),
        ])
        let c = CounterSignature(reportId: Array(repeating: 5, count: 32), name: "Mr Okafor", phone: "08012345678", signatureHash: Array(repeating: 6, count: 32), signedAt: 1_820_003_600)
        let data = ReportPDF.render(movedOut, id: String(repeating: "cd", count: 32), publicKey: [UInt8](repeating: 4, count: 65), movedIn: movedIn, signature: (c, nil)) { _ in URL(fileURLWithPath: "/nonexistent.jpg") }
        let pdf = try XCTUnwrap(PDFDocument(data: data))
        let text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string?.replacingOccurrences(of: "\n", with: " ") }
        XCTAssertEqual(pdf.pageCount, 6, "cover, the room, the contact sheet, the changes, the signature, the last page")
        XCTAssertTrue(text[3].contains(ReportText.sinceMoveIn))
        XCTAssertTrue(text[3].contains("Cracked tile — same") && text[3].contains("Fine → Snag") && text[3].contains("— changed") && text[3].contains("Burn on the hob — new"), text[3])
        XCTAssertFalse(text[3].contains("₦"), "never a number about money")
        XCTAssertTrue(text[4].contains("Mr Okafor") && text[4].contains("08012345678") && text[4].contains(ReportText.signaturePage), text[4])
    }

    func testThePDFIsSetInInterAndTheQRCarriesTheIdAndTheKeyFingerprint() throws {
        XCTAssertTrue(ReportPDF.font(12).familyName.hasPrefix("Inter"), "DESIGN.md: the PDF is set in the face the app is — got \(ReportPDF.font(12).familyName)")
        let key = [UInt8](repeating: 4, count: 65)
        let payload = ReportPDF.qrPayload(id: "ab", publicKey: key)
        XCTAssertTrue(payload.hasPrefix("snag:1:ab:"))
        XCTAssertEqual(payload.split(separator: ":").last?.count, 16, "eight bytes of the key's hash, as hex")
        let image = try XCTUnwrap(ReportPDF.qrImage(payload))
        // Read it back with Vision's own detector: the code says what it was given.
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
        let features = detector.features(in: CIImage(cgImage: try XCTUnwrap(image.cgImage)))
        XCTAssertEqual((features.first as? CIQRCodeFeature)?.messageString, payload)
    }
}
