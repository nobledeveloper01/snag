// The measured and scanned tiers on the simulator, which has neither
// sensor: the fixture room stands in for the taps and for the scan, and
// everything after the sensor — the numbers, the chip, the plan, the seal,
// the PDF — is proved. R1 and R2 are the sensors.
import XCTest

final class TierTests: XCTestCase {
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
    func testARoomIsMeasuredThenScannedAndTheReportCarriesTheTier() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-fixtureFloors", "-freshStore"]
        app.launch()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let address = app.textViews["address"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        type("5 Tier Street", into: address, in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.navigationBars["5 rooms"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(identifier: "photographed").count, 5)
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Measure this room"].waitForExistence(timeout: 3))
        try audit(app, "room with the tier buttons")

        // Measured: the fixture's tapped corners.
        app.buttons["Measure this room"].tap()
        XCTAssertTrue(app.buttons["fixtureCorners"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["useMeasurement"].isEnabled, "no corners, no measurement")
        try audit(app, "measure, empty")
        app.buttons["fixtureCorners"].tap()
        XCTAssertTrue(app.staticTexts["dimensions"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["cornerCount"].label, "4 corners")
        XCTAssertEqual(app.staticTexts["dimensions"].label, "3.63 × 4.23 m · 15.1 m²", "the tightest rectangle along the longest edge of four uneven taps")
        try audit(app, "measure, four corners")
        app.buttons["useMeasurement"].tap()
        XCTAssertTrue(app.staticTexts["roomDimensions"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["roomDimensions"].label.contains("measured"), app.staticTexts["roomDimensions"].label)
        try audit(app, "room, measured")

        // Scanned: the fixture floor, with its plan.
        app.buttons["Scan this room"].tap()
        XCTAssertTrue(app.buttons["fixtureScan"].waitForExistence(timeout: 3))
        app.buttons["fixtureScan"].tap()
        XCTAssertTrue(app.staticTexts["dimensions"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["dimensions"].label, "3.60 × 4.20 m · 15.1 m²")
        XCTAssertTrue(app.images["Floor plan"].exists, "the plan is drawn before it is used")
        try audit(app, "scan, room closed")
        app.buttons["useScan"].tap()
        XCTAssertTrue(app.staticTexts["roomDimensions"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["roomDimensions"].label.contains("scanned"), "a scan outranks a measurement")
        XCTAssertFalse(app.buttons["Measure this room"].isEnabled, "and a tap cannot overwrite a scan")

        // A photograph, then the seal: the report's tier is the highest in it.
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(identifier: "scanned").count, 1, "the kitchen's chip says scanned")
        XCTAssertEqual(app.staticTexts.matching(identifier: "photographed").count, 4, "the other rooms say what they are")
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10), "the bundle, plan and all, verifies")
        XCTAssertTrue(app.staticTexts["1 snags · scanned"].exists || app.staticTexts["0 snags · scanned"].exists, "the sealed screen names the report's tier")
        app.terminate()
    }

    @MainActor
    func testASealedReportIsScannedLaterAsAnAmendmentAndStillVerifies() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-fixtureFloors", "-freshStore"]
        app.launch()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let address = app.textViews["address"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        choose(template: "Self-contain", in: app)
        type("6 Amend Close", into: address, in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.navigationBars["3 rooms"].waitForExistence(timeout: 3))
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["1 snags · photographed"].exists)
        // Later: the kitchen scanned, as an amendment; the first seal stands.
        XCTAssertTrue(reveal(app.buttons["Measure or scan later"], in: app))
        app.buttons["Measure or scan later"].tap()
        XCTAssertTrue(app.buttons["sealAmendment"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["sealAmendment"].isEnabled, "nothing changed, nothing to seal")
        try audit(app, "amend, untouched")
        XCTAssertTrue(reveal(app.buttons["scan-1"], in: app))
        app.buttons["scan-1"].tap()
        XCTAssertTrue(app.buttons["fixtureScan"].waitForExistence(timeout: 3))
        app.buttons["fixtureScan"].tap()
        XCTAssertTrue(app.buttons["useScan"].waitForExistence(timeout: 3))
        app.buttons["useScan"].tap()
        XCTAssertTrue(app.buttons["sealAmendment"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["sealAmendment"].isEnabled)
        try audit(app, "amend, one room scanned")
        app.buttons["sealAmendment"].tap()
        XCTAssertTrue(app.staticTexts["amended"].waitForExistence(timeout: 10), "the sealed screen says when it was amended")
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].exists, "both layers verify")
        XCTAssertTrue(app.staticTexts["1 snags · scanned"].exists, "the report shown is the amended one")
        try audit(app, "sealed and amended")
        app.terminate()

        // Relaunched: the amendment is still what is shown, still unaltered.
        let again = XCUIApplication()
        again.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-fixtureFloors"]
        again.launch()
        XCTAssertTrue(again.staticTexts["6 Amend Close"].waitForExistence(timeout: 5))
        again.staticTexts["6 Amend Close"].firstMatch.tap()
        XCTAssertTrue(again.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
        XCTAssertTrue(reveal(again.staticTexts["amended"], in: again))
        again.terminate()
    }
}
