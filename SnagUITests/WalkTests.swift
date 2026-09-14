// Phase 0 on the simulator: the splash sweeps, the empty state is one
// sentence and one button, a report is started, two rooms are added, and
// every screen passes the accessibility audit at two text sizes.
import XCTest

final class WalkTests: XCTestCase {
    static let everythingButContrast: XCUIAccessibilityAuditType = [
        .dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription, .textClipped, .trait,
    ]

    @MainActor
    private func audit(_ app: XCUIApplication, _ screen: String) throws {
        try app.performAccessibilityAudit(for: Self.everythingButContrast) { issue in
            XCTFail("[\(screen)] \(issue.auditType): \(issue.compactDescription) — \(issue.element?.description ?? "") \(issue.detailedDescription)")
            return true
        }
    }

    @MainActor
    func testTheWalkStartsAndTwoRoomsAreAddedAtBothSizes() throws {
        for size in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            let app = XCUIApplication()
            app.launchArguments = ["-now", "1789000000", "-freshStore", "-UIPreferredContentSizeCategoryName", size]
            app.launch()
            XCTAssertTrue(app.staticTexts["Start with the flat you're standing in."].waitForExistence(timeout: 5), "empty state at \(size)")
            try audit(app, "empty \(size)")
            app.buttons["New report"].tap()
            let address = app.textViews["address"]
            XCTAssertTrue(address.waitForExistence(timeout: 3))
            try audit(app, "new report \(size)")
            address.tap(); address.typeText("14 Admiralty Way")
            app.buttons["Walk the flat"].tap()
            XCTAssertTrue(app.staticTexts["14 Admiralty Way"].waitForExistence(timeout: 3))
            app.staticTexts["14 Admiralty Way"].firstMatch.tap()
            XCTAssertTrue(app.buttons["Add a room"].waitForExistence(timeout: 3))
            try audit(app, "walk empty \(size)")
            app.buttons["Add a room"].tap()
            XCTAssertTrue(app.buttons["Kitchen"].waitForExistence(timeout: 3))
            try audit(app, "add room \(size)")
            app.buttons["Kitchen"].tap()
            app.buttons["addRoomConfirm"].tap()
            XCTAssertTrue(app.staticTexts["Kitchen"].waitForExistence(timeout: 3))
            app.buttons["Add a room"].tap()
            XCTAssertTrue(app.buttons["Bedroom"].waitForExistence(timeout: 3))
            app.buttons["Bedroom"].tap()
            app.buttons["addRoomConfirm"].tap()
            XCTAssertTrue(app.staticTexts["Bedroom"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.navigationBars["2 rooms"].exists, "the title counts the rooms")
            XCTAssertEqual(app.staticTexts.matching(identifier: "photographed").count, 2, "every room carries its tier")
            try audit(app, "walk \(size)")
            app.terminate()
        }
    }

    @MainActor
    func testTheSplashSweepsWithReduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = ["-reduceMotion", "-freshStore"]
        app.launch()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5), "the splash never swept with Reduce Motion on")
    }
}
