// Phase 1 on the simulator: a room is photographed from a fixture, the
// item gets a caption, the report is reviewed and sealed, and the sealed
// screen verifies its own bundle. Then the same bundle with one byte
// flipped, and the screen says so. Two launches of the same app; the
// second must not say "Unaltered".
import XCTest

final class SealTests: XCTestCase {
    // Not `.contrast`: it cannot read the gradient the app is drawn on, and
    // `ContrastTests` asserts every pair itself. Not `.dynamicType` either:
    // it measures a row's growth in place and calls a row near the bottom
    // of a list "partially unsupported" when its grown frame would cross
    // the edge, whatever the row does when it is actually laid out — the
    // paper-check screen was screenshotted at L and at AX5 and scales, and
    // the audit failed it three different rows in a row. Dynamic Type is
    // gated by `design-check` (every font is relative to a text style) and
    // by `.textClipped` at the largest size, which is what a person sees.
    static let everythingButContrast: XCUIAccessibilityAuditType = [
        .elementDetection, .hitRegion, .sufficientElementDescription, .textClipped, .trait,
    ]

    @MainActor
    private func audit(_ app: XCUIApplication, _ screen: String) throws {
        try app.performAccessibilityAudit(for: Self.everythingButContrast) { issue in
            XCTFail("[\(screen)] \(issue.auditType): \(issue.compactDescription) — \(issue.element?.description ?? "") \(issue.detailedDescription)")
            return true
        }
    }

    @MainActor
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-freshStore"] + extra
        app.launch()
        return app
    }

    @MainActor
    private func addRoom(_ app: XCUIApplication, _ name: String) throws {
        app.buttons["Add a room"].tap()
        XCTAssertTrue(app.buttons[name].waitForExistence(timeout: 3))
        app.buttons[name].tap()
        app.buttons["addRoomConfirm"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 3))
    }

    /// The shutter, the fixture photograph, the sheet, a caption, snag or fine, Done.
    @MainActor
    private func photograph(_ app: XCUIApplication, caption: String, fine: Bool, auditAs: String? = nil) throws {
        app.buttons["Photograph"].tap()
        let field = app.textViews["caption"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "the fixture photograph arrived and the item sheet opened — \(app.debugDescription.prefix(3000))")
        if let auditAs { try audit(app, auditAs) }
        if !caption.isEmpty { field.tap(); field.typeText(caption) }
        if fine { app.buttons["Fine"].tap() }
        app.buttons["Done"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testAReportIsPhotographedSealedAndVerifiesItself() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let address = app.textViews["address"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        choose(template: "No rooms yet", in: app)   // before the keyboard is up
        type("7 Bourdillon Road", into: address, in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.staticTexts["7 Bourdillon Road"].waitForExistence(timeout: 3))
        app.staticTexts["7 Bourdillon Road"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Add a room"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Review"].exists, "nothing to review before a photograph")
        // Two rooms, six items: the shape the roadmap's exit gate names.
        try addRoom(app, "Kitchen")
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        try audit(app, "room empty")
        try photograph(app, caption: "Cracked tile by the sink", fine: false, auditAs: "item sheet")
        XCTAssertTrue(app.staticTexts["Cracked tile by the sink"].waitForExistence(timeout: 3))
        try audit(app, "room with item")
        try photograph(app, caption: "", fine: true)
        XCTAssertTrue(app.staticTexts["No caption"].waitForExistence(timeout: 3))
        try photograph(app, caption: "Tap drips", fine: false)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["3 items · 2 snags"].exists, "the room row counts")
        try addRoom(app, "Bedroom")
        app.staticTexts["Bedroom"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        try photograph(app, caption: "Window latch broken", fine: false)
        try photograph(app, caption: "Wardrobe door", fine: true)
        try photograph(app, caption: "Damp patch above the bed", fine: false)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["3 items · 2 snags"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["2 rooms"].exists)
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        try audit(app, "review")
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10), "the sealed screen verified its own bundle")
        XCTAssertTrue(app.navigationBars["Sealed"].exists)
        XCTAssertTrue(app.buttons["Share PDF"].waitForExistence(timeout: 5), "the PDF rendered")
        XCTAssertTrue(app.buttons["Share sealed bundle"].exists)
        try audit(app, "sealed")
        XCTAssertTrue(reveal(app.buttons["rooms"], in: app))
        app.buttons["rooms"].tap()
        XCTAssertTrue(app.staticTexts["Cracked tile by the sink"].waitForExistence(timeout: 3), "the sealed rooms are readable")
        XCTAssertEqual(app.staticTexts.matching(identifier: "photographed").count, 2, "both rooms carry their tier")
        try audit(app, "sealed rooms")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Share PDF"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Sealed"].waitForExistence(timeout: 3), "the list has a sealed section")
        XCTAssertFalse(app.staticTexts["In progress"].exists, "the draft is gone")
        try audit(app, "list with a sealed report")
        app.terminate()

        // The cover's code, read off the latest sealed report, names a bundle here.
        let paper = XCUIApplication()
        paper.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-scanLatest"]
        paper.launch()
        XCTAssertTrue(paper.navigationBars["Check a paper copy"].waitForExistence(timeout: 8))
        XCTAssertTrue(paper.staticTexts["Matches the report at 7 Bourdillon Road"].waitForExistence(timeout: 8), "the code matched the bundle on this phone")
        XCTAssertTrue(paper.staticTexts["Unaltered since signing"].exists)
        try audit(paper, "paper check")
        let code = paper.textViews["code"]
        type(" x", into: code, in: paper)     // not a code any more
        paper.buttons["Check"].tap()
        XCTAssertTrue(paper.staticTexts["That is not a Snag code."].waitForExistence(timeout: 3))
        paper.buttons["Done"].tap()
        paper.terminate()

        // Same store, one byte flipped before the verifier runs.
        let again = XCUIApplication()
        again.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-tamper"]
        again.launch()
        XCTAssertTrue(again.staticTexts["7 Bourdillon Road"].waitForExistence(timeout: 5))
        again.staticTexts["7 Bourdillon Road"].firstMatch.tap()
        XCTAssertTrue(again.staticTexts["Altered"].waitForExistence(timeout: 10), "a flipped byte is seen on the screen, not only in a unit test")
        XCTAssertFalse(again.staticTexts["Unaltered since signing"].exists)
        try audit(again, "altered")
        again.terminate()

        // The same bundle, opened as another phone would open it: through the
        // document path, with the verifier and nothing else.
        let opener = XCUIApplication()
        opener.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-openLatest"]
        opener.launch()
        XCTAssertTrue(opener.navigationBars["Opened report"].waitForExistence(timeout: 10), "an opened bundle shows the verify screen")
        XCTAssertTrue(opener.staticTexts["Altered"].waitForExistence(timeout: 10), "the tampered bundle stays altered wherever it is opened")
        try audit(opener, "opened altered")
        opener.buttons["Done"].tap()
        opener.terminate()
    }
}
