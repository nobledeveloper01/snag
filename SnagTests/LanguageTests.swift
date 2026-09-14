// Every language answers every string, and the PDF keeps the English.
import PDFKit
import XCTest
import SnagDomain
@testable import Snag

final class LanguageTests: XCTestCase {
    override func tearDown() { L10n.language = .english }

    func testEveryLanguageAnswersAndEnglishIsTheFallbackNobodySees() {
        for l in Language.allCases where l != .english {
            L10n.language = l
            XCTAssertNotEqual(Strings.emptyTitle, "Start with the flat you're standing in.", "\(l.name) has its own empty state")
            XCTAssertEqual(Strings.appName, "Snag", "the name is the name in every language")
            XCTAssertEqual(l.table.count, Language.pidgin.table.count, "\(l.name) has every string the others have")
            XCTAssertFalse(l.table.values.contains(""), "no empty translation in \(l.name)")
        }
        L10n.language = .english
        XCTAssertEqual(Strings.emptyTitle, "Start with the flat you're standing in.")
        XCTAssertEqual(L10n.t("a string the tables do not have"), "a string the tables do not have", "the fallback is the English itself")
    }

    func testThePDFKeepsTheEnglishAboveTheTranslation() throws {
        L10n.language = .yoruba
        let report = Report(kind: .moveIn, address: "1 Èdè Street", createdAt: 1_789_000_000, rooms: [Room(name: .kitchen)])
        let data = ReportPDF.render(report, id: String(repeating: "aa", count: 32), publicKey: [UInt8](repeating: 4, count: 65)) { _ in URL(fileURLWithPath: "/nonexistent.jpg") }
        let pdf = try XCTUnwrap(PDFDocument(data: data))
        let last = try XCTUnwrap(pdf.page(at: pdf.pageCount - 1)?.string?.replacingOccurrences(of: "\n", with: " "))
        XCTAssertTrue(last.contains("What this report is"), "the English heading stays")
        XCTAssertTrue(last.contains("It does not say what any party owes."), "the English body stays")
        // PDF text extraction is unkind to Yorùbá tone marks; the words
        // without them, and the length, say the translation is there.
        XCTAssertTrue(last.contains("Ohun t"), "and the Yorùbá follows it — \(last.suffix(300))")
        XCTAssertGreaterThan(last.count, 900, "two bodies on the page, not one")
        L10n.language = .english
        let en = ReportPDF.render(report, id: String(repeating: "aa", count: 32), publicKey: [UInt8](repeating: 4, count: 65)) { _ in URL(fileURLWithPath: "/nonexistent.jpg") }
        let enLast = try XCTUnwrap(PDFDocument(data: en)?.page(at: PDFDocument(data: en)!.pageCount - 1)?.string ?? "")
        XCTAssertFalse(enLast.contains("Ohun t"), "in English the page is English only")
        XCTAssertLessThan(enLast.count, last.count)
    }
}
