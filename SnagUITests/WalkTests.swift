// Phase 0 on the simulator: the splash sweeps, the empty state is one
// sentence and one button, a report is started, two rooms are added, and
// every screen passes the accessibility audit at two text sizes.
import XCTest

final class WalkTests: XCTestCase {
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
            choose(template: "No rooms yet", in: app)   // before the keyboard is up
            type("14 Admiralty Way", into: address, in: app)
            app.buttons["Walk the flat"].tap()
            XCTAssertTrue(app.staticTexts["14 Admiralty Way"].waitForExistence(timeout: 3))
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

extension XCTestCase {
    /// The template rows sit below the fold at some sizes; scroll until the one wanted is there.
    @MainActor
    func choose(template: String, in app: XCUIApplication) {
        let row = app.buttons[template]
        var tries = 0
        while !row.exists && tries < 4 { app.swipeUp(); tries += 1 }
        XCTAssertTrue(row.waitForExistence(timeout: 2), "template row \(template)")
        row.tap()
        // Back to the top, until the address editor is clear of the title
        // bar: a tap on a row half under the bar focuses nothing.
        tries = 0
        while !(app.textViews["address"].exists && app.textViews["address"].frame.minY > 150) && tries < 4 { app.swipeDown(); tries += 1 }
    }

    /// Tap a field until the keyboard is up, then type. A tap that lands
    /// while a list is still settling after a swipe does not focus.
    @MainActor
    func type(_ text: String, into field: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        field.tap()
        while app.keyboards.count == 0 && tries < 3 { Thread.sleep(forTimeInterval: 0.4); field.tap(); tries += 1 }
        field.typeText(text)
    }

    /// Scroll a list until an element is on screen, or give up.
    @MainActor
    func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        var tries = 0
        while !element.exists && tries < 4 { app.swipeUp(); tries += 1 }
        return element.waitForExistence(timeout: 2)
    }
}
