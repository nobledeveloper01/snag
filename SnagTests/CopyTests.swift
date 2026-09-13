// Nothing the app or the PDF says claims proof. ADR-0003. `make copy-check`
// reads the source files without building; this reads the strings at
// runtime so the two cannot drift.
import XCTest
@testable import Snag

final class CopyTests: XCTestCase {
    static let banned = ["proof", "proofs", "prove", "proves", "proven", "certified", "certify", "notarised", "notarized", "verified", "verify", "verifies"]

    func testNothingClaimsProof() {
        let mirror = Mirror(reflecting: Strings.self)
        _ = mirror
        let everything: [String] = [
            Strings.appName, Strings.emptyTitle, Strings.emptyHint, Strings.unaltered, Strings.altered, Strings.alteredHint,
            Strings.datedByPhone, Strings.seal, Strings.sealed, ReportText.title, ReportText.whatThisIs,
        ] + ReportText.whatThisIsBody
        for s in everything {
            let words = s.lowercased().split { !$0.isLetter }.map(String.init)
            for w in Self.banned { XCTAssertFalse(words.contains(w), "'\(w)' in: \(s)") }
        }
    }

    func testTheLastPageSaysWhatTheDateIs() {
        XCTAssertTrue(ReportText.whatThisIsBody.contains { $0.contains("phone's own") }, "the report must say the date is the phone's")
        XCTAssertTrue(ReportText.whatThisIsBody.contains { $0.contains("does not say what any party owes") })
    }
}
