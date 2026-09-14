// The thirty, part three, on the simulator: a report is found by its
// address, the settings are read and audited, the lock shows its screen
// (and, on a simulator with no passcode, says honestly that it could not
// unlock), and the intent's path opens the new-report sheet.
import XCTest

final class DepthUITests: XCTestCase {
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
    private func launch(_ extra: [String] = [], fresh: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos"] + (fresh ? ["-freshStore"] : []) + extra
        app.launch()
        return app
    }

    @MainActor
    private func startDraft(_ app: XCUIApplication, _ address: String) {
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let field = app.textViews["address"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        type(address, into: field, in: app)
        app.buttons["Walk the flat"].tap()
        // Walk the flat walks: the draft opens. Back to the list for the next one.
        XCTAssertTrue(app.buttons["Add a room"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts[address].waitForExistence(timeout: 3))
    }

    @MainActor
    func testAReportIsFoundByItsAddress() throws {
        let app = launch()
        startDraft(app, "1 Glover Road")
        startDraft(app, "2 Bourdillon Road")
        XCTAssertFalse(app.textFields["search"].exists, "no search with two reports")
        startDraft(app, "3 Milverton Road")
        let search = app.textFields["search"]
        XCTAssertTrue(search.waitForExistence(timeout: 3), "three reports, and a way to find one")
        try audit(app, "list with search")
        search.tap(); search.typeText("bourd")
        XCTAssertTrue(app.staticTexts["2 Bourdillon Road"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["1 Glover Road"].exists, "the others are filtered out")
        XCTAssertFalse(app.staticTexts["3 Milverton Road"].exists)
        app.terminate()
    }

    @MainActor
    func testTheSettingsAreReadAndTheLockShowsItsScreen() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["lang-en"].waitForExistence(timeout: 3))
        // Audited before it is scrolled — a scrolled List reports rows that
        // straddle its edges as clipped, whatever they do when laid out.
        try audit(app, "settings")
        XCTAssertTrue(reveal(app.switches["nudge"], in: app))
        XCTAssertTrue(app.switches["lock"].exists)
        XCTAssertTrue(reveal(app.buttons["Restore from a backup"], in: app))
        app.buttons["Done"].tap()
        app.terminate()

        // The lock on: the locked screen, and — on a simulator with no
        // passcode — the honest answer that it could not unlock.
        let locked = launch(["-lock"], fresh: false)
        XCTAssertTrue(locked.staticTexts["Snag is locked."].waitForExistence(timeout: 5))
        XCTAssertTrue(locked.buttons["Unlock"].exists)
        XCTAssertFalse(locked.buttons["New report"].exists, "nothing behind the lock is shown")
        // The simulator answers device-owner authentication with a passcode
        // sheet of its own. Cancel it, and the lock says it did not unlock.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sheet = springboard.staticTexts["Enter iPhone Passcode for “Snag”"]
        if sheet.waitForExistence(timeout: 5) {
            if springboard.buttons["Cancel"].exists { springboard.buttons["Cancel"].tap() } else { springboard.typeText("\n") }
        }
        XCTAssertTrue(locked.staticTexts["unlockFailed"].waitForExistence(timeout: 8) || locked.buttons["New report"].waitForExistence(timeout: 2),
                      "either the lock says it did not unlock, or the simulator's passcode let it through")
        XCTAssertFalse(locked.buttons["New report"].exists, "cancelled, the reports stay behind the lock")
        try audit(locked, "locked")
        locked.terminate()
    }

    @MainActor
    func testTheIntentsPathOpensTheNewReportSheet() throws {
        let app = launch(["-newReport"])
        XCTAssertTrue(app.textViews["address"].waitForExistence(timeout: 6), "the sheet opened on its own")
        app.buttons["Cancel"].tap()
        app.terminate()
    }
}
