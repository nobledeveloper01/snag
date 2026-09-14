// The thirty, part one, on the simulator: a template names the rooms, a
// room is renamed and removed, a prompt starts a caption, the meter and the
// keys take a number, an item is edited and deleted, the same photograph
// twice is refused, and a killed app resumes in the room it was in.
import XCTest

final class WalkFeaturesTests: XCTestCase {
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
    private func launch(_ extra: [String] = [], fresh: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos"] + (fresh ? ["-freshStore"] : []) + extra
        app.launch()
        return app
    }

    /// A chip in the strip is in the hierarchy before it is on screen;
    /// `isHittable` throws on one that is off the edge, so the frame decides.
    @MainActor
    private func onScreen(_ e: XCUIElement, in app: XCUIApplication) -> Bool {
        e.exists && e.frame.minX >= 0 && e.frame.maxX <= app.frame.maxX
    }

    /// A swipe on a navigation row is sometimes read as a tap and opens the
    /// room; a press-and-drag across the row is read as a swipe every time.
    @MainActor
    private func swipeRow(_ e: XCUIElement) {
        let start = e.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = e.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    @MainActor
    private func startTwoBed(_ app: XCUIApplication, size: String? = nil) {
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let address = app.textViews["address"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        choose(template: "Two bedroom", in: app)   // before the keyboard is up
        type("3 Glover Road", into: address, in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.staticTexts["3 Glover Road"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["7 rooms"].waitForExistence(timeout: 3), "the two-bedroom template names seven rooms")
    }

    @MainActor
    func testATemplateNamesTheRoomsAndTheyCanBeRenamedReorderedAndRemoved() throws {
        for size in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            let app = launch(["-UIPreferredContentSizeCategoryName", size])
            XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
            app.buttons["New report"].tap()
            XCTAssertTrue(reveal(app.buttons["Two bedroom"], in: app), "the template rows are on the sheet at \(size)")
            try audit(app, "new report with templates \(size)")
            app.terminate()
        }
        let app = launch()
        startTwoBed(app)
        XCTAssertTrue(app.staticTexts["Bedroom 1"].exists && app.staticTexts["Bedroom 2"].exists, "rooms that share a name are numbered — saw \(app.staticTexts.allElementsBoundByIndex.map(\.label))")
        XCTAssertTrue(app.buttons["Reorder rooms"].exists)
        try audit(app, "walk with seven rooms")
        app.buttons["Reorder rooms"].tap()
        XCTAssertTrue(app.buttons["Done reordering"].waitForExistence(timeout: 3))
        app.buttons["Done reordering"].tap()
        // Rename Balcony to the tenant's own name.
        XCTAssertTrue(reveal(app.staticTexts["Balcony"], in: app))
        swipeRow(app.staticTexts["Balcony"].firstMatch)
        XCTAssertTrue(app.buttons["Rename"].waitForExistence(timeout: 3))
        app.buttons["Rename"].tap()
        XCTAssertTrue(reveal(app.buttons["Other"], in: app), "the rename sheet — \(app.debugDescription.prefix(2000))")
        app.buttons["Other"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap(); field.typeText("Boys' quarters")
        app.buttons["addRoomConfirm"].tap()
        XCTAssertTrue(app.staticTexts["Boys' quarters"].waitForExistence(timeout: 3), "the room was renamed")
        XCTAssertTrue(app.buttons["addRoomConfirm"].waitForNonExistence(timeout: 3), "the sheet is gone before the next swipe")
        XCTAssertFalse(app.staticTexts["Balcony"].exists)
        // Remove the toilet.
        XCTAssertTrue(reveal(app.staticTexts["Toilet"], in: app))
        swipeRow(app.staticTexts["Toilet"].firstMatch)
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3), "swipe actions on the toilet row")
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.navigationBars["6 rooms"].waitForExistence(timeout: 3), "the room was removed")
        app.terminate()
    }

    @MainActor
    func testADarkPhotographIsSaidToBeDark() throws {
        let app = launch(["-darkFixture"])
        startTwoBed(app)
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["issue"].exists, "the judge's word is on the sheet")
        XCTAssertTrue(app.staticTexts["issue"].label.contains("Too dark"), app.staticTexts["issue"].label)
        try audit(app, "item sheet with a warning")
        app.buttons["Cancel"].tap()
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["issue"].exists, "the second shot is fine and says nothing")
        app.buttons["Cancel"].tap()
        app.terminate()
    }

    @MainActor
    func testPromptsMeterKeysEditDeleteAndTheDuplicateRule() throws {
        let app = launch(["-repeatFixture"])
        startTwoBed(app)
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Tap"].exists, "the kitchen's prompts are on the shutter")
        try audit(app, "room with prompts")
        // A prompt starts the caption.
        app.buttons["Tap"].tap()
        let caption = app.textViews["caption"]
        XCTAssertTrue(caption.waitForExistence(timeout: 5))
        caption.tap(); caption.typeText("drips when closed")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Tap — drips when closed"].waitForExistence(timeout: 3), "the prompt is the start of the sentence")
        // The same photograph again is refused (-repeatFixture repeats shot 1 as shot 2).
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.staticTexts["duplicate"].waitForExistence(timeout: 5), "one photograph is one item")
        try audit(app, "duplicate refused")
        app.buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts["duplicate"].waitForNonExistence(timeout: 3))
        // The meter asks for a number and puts it in the caption. Its chip is
        // at the end of the strip, so the strip is scrolled to it.
        let strip = app.scrollViews["prompts"]
        XCTAssertTrue(strip.waitForExistence(timeout: 3), "the prompt strip — \(app.debugDescription.prefix(2500))")
        var tries = 0
        while !onScreen(app.buttons["Prepaid meter"], in: app) && tries < 4 { strip.swipeLeft(); tries += 1 }
        app.buttons["Prepaid meter"].tap()
        let reading = app.textFields["reading"]
        XCTAssertTrue(reading.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Done"].isEnabled, "no reading, no item")
        try audit(app, "meter sheet")
        reading.tap(); reading.typeText("4512.7")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Prepaid meter: 4512.7 units"].waitForExistence(timeout: 3))
        // The keys count.
        tries = 0
        while !onScreen(app.buttons["Keys"], in: app) && tries < 4 { strip.swipeLeft(); tries += 1 }
        app.buttons["Keys"].tap()
        XCTAssertTrue(app.steppers["keys"].waitForExistence(timeout: 5))
        app.steppers["keys"].buttons["keys-Increment"].tap()
        app.steppers["keys"].buttons["keys-Increment"].tap()
        try audit(app, "keys sheet")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Keys handed over: 3"].waitForExistence(timeout: 3))
        // Edit the first item: it becomes fine, its caption changes.
        app.staticTexts["Tap — drips when closed"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit"].waitForExistence(timeout: 3))
        app.buttons["Fine"].tap()
        caption.tap(); caption.typeText("Agent fixed it. ")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Agent fixed it.'")).firstMatch.waitForExistence(timeout: 3), "the caption was edited")
        // Delete the meter item.
        app.staticTexts["Prepaid meter: 4512.7 units"].firstMatch.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Prepaid meter: 4512.7 units"].waitForNonExistence(timeout: 3), "the item was removed")
        try audit(app, "room after edits")
        app.terminate()

        // A draft survives a kill: the app comes back in the kitchen, items intact.
        let again = launch(fresh: false)
        XCTAssertTrue(again.navigationBars["Kitchen"].waitForExistence(timeout: 8), "the walk resumed in the room it was in")
        XCTAssertTrue(again.staticTexts["Keys handed over: 3"].exists)
        XCTAssertTrue(again.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Agent fixed it.'")).firstMatch.exists)
        again.terminate()
    }
}
