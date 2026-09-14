// The thirty, part two, on the simulator: a sealed move-in is
// counter-signed on glass, a reminder goes into the calendar, and a
// move-out linked to it starts with its rooms, shoots the same view, and
// says what changed.
import XCTest

final class HandoverTests: XCTestCase {
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

    /// A one-bedroom move-in with one kitchen photograph, sealed.
    @MainActor
    private func sealMoveIn(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        app.buttons["New report"].tap()
        let address = app.textViews["address"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        type("9 Milverton Road", into: address, in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.staticTexts["9 Milverton Road"].waitForExistence(timeout: 3))
        app.staticTexts["9 Milverton Road"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["5 rooms"].waitForExistence(timeout: 3))
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        app.buttons["Photograph"].tap()
        let caption = app.textViews["caption"]
        XCTAssertTrue(caption.waitForExistence(timeout: 5))
        caption.tap(); caption.typeText("Chipped worktop")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Chipped worktop"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testTheOtherPartySignsOnGlassAndTheBundleStillVerifies() throws {
        let app = launch()
        sealMoveIn(app)
        XCTAssertTrue(reveal(app.buttons["Counter-sign"], in: app))
        app.buttons["Counter-sign"].tap()
        let name = app.textFields["name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        try audit(app, "counter-sign empty")
        XCTAssertFalse(app.buttons["signConfirm"].isEnabled, "no name, no signature, no button")
        name.tap(); name.typeText("Mr Okafor")
        let phone = app.textFields["phone"]
        phone.tap(); phone.typeText("08012345678")
        // The keyboard down, the pad in view, then a signature: a press-and-drag across it.
        app.buttons["keyboardDone"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "the keyboard leaves on Done")
        let pad = app.otherElements["pad"]
        XCTAssertTrue(reveal(pad, in: app), "the pad — \(app.debugDescription.prefix(1500))")
        pad.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.6)).press(forDuration: 0.1, thenDragTo: pad.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.4)))
        XCTAssertTrue(app.buttons["signConfirm"].isEnabled, "a name and a stroke enable the seal")
        app.buttons["signConfirm"].tap()
        XCTAssertTrue(app.staticTexts["counterSigned"].waitForExistence(timeout: 10), "the sealed screen names the signer")
        XCTAssertTrue(app.staticTexts["counterSigned"].label.contains("Mr Okafor"))
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].exists, "the bundle, with its second layer, still verifies")
        XCTAssertFalse(app.buttons["Counter-sign"].exists, "signed once")
        try audit(app, "sealed and counter-signed")
        app.terminate()

        // Relaunched, the counter-signature is still there and the bundle still verifies.
        let again = launch(fresh: false)
        XCTAssertTrue(again.staticTexts["9 Milverton Road"].waitForExistence(timeout: 5))
        again.staticTexts["9 Milverton Road"].firstMatch.tap()
        XCTAssertTrue(again.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
        XCTAssertTrue(reveal(again.staticTexts["counterSigned"], in: again))
        again.terminate()
    }

    @MainActor
    func testAReminderGoesIntoTheCalendar() throws {
        let app = launch()
        sealMoveIn(app)
        XCTAssertTrue(reveal(app.buttons["Remind me to walk out with Snag"], in: app))
        app.buttons["Remind me to walk out with Snag"].tap()
        XCTAssertTrue(app.buttons["Add to my calendar"].waitForExistence(timeout: 3))
        try audit(app, "remind")
        // The calendar permission, if the simulator asks.
        let monitor = addUIInterruptionMonitor(withDescription: "calendar") { alert in
            for label in ["Allow", "OK", "Allow Full Access"] where alert.buttons[label].exists { alert.buttons[label].tap(); return true }
            return false
        }
        app.buttons["Add to my calendar"].tap()
        // The permission sheet is SpringBoard's; the monitor above handles it
        // when it fires, and this handles it when — as on the CI runner — it
        // does not.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow Full Access", "Allow", "OK"] where springboard.buttons[label].waitForExistence(timeout: 3) {
            springboard.buttons[label].tap(); break
        }
        app.tap()   // nudges the interruption monitor
        let outcome = app.staticTexts["outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 30), "an outcome, one way or the other — \(springboard.debugDescription.prefix(800))")
        XCTAssertEqual(outcome.label, "In your calendar.", "the event was written")
        removeUIInterruptionMonitor(monitor)
        app.buttons["Done"].tap()
        app.terminate()
    }

    @MainActor
    func testAMoveOutLinkedToTheMoveInStartsWithItsRoomsAndSaysWhatChanged() throws {
        let app = launch()
        sealMoveIn(app)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 3))
        app.buttons["New report"].tap()
        XCTAssertTrue(app.buttons["Move-out"].waitForExistence(timeout: 3))
        app.buttons["Move-out"].tap()
        XCTAssertTrue(app.buttons["9 Milverton Road"].waitForExistence(timeout: 3), "the sealed move-in is offered as the link")
        app.buttons["9 Milverton Road"].tap()
        XCTAssertFalse(app.buttons["Two bedroom"].exists, "linked, the rooms come from the move-in, not a template")
        try audit(app, "new move-out")
        XCTAssertTrue(app.buttons["Walk the flat"].isEnabled, "the address came from the move-in")
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 3))
        app.staticTexts["9 Milverton Road"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["5 rooms"].waitForExistence(timeout: 3), "the move-in's five rooms")
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Chipped worktop"].exists, "the move-in's photograph of this room sits beside the shutter")
        try audit(app, "room with the move-in views")
        app.buttons["Chipped worktop"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.buttons["Fine"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Chipped worktop"].waitForExistence(timeout: 3), "the same view, captioned the same")
        app.buttons["Photograph"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.textViews["caption"].tap(); app.textViews["caption"].typeText("Burn mark on the hob")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Burn mark on the hob"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
        XCTAssertTrue(reveal(app.staticTexts["Since move-in"], in: app), "the sealed move-out compares itself to the move-in — \(app.staticTexts.allElementsBoundByIndex.map(\.label))")
        let changed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Chipped worktop' AND label CONTAINS 'changed'")).firstMatch
        XCTAssertTrue(changed.exists, "a new photograph of the same view, now fine, is a change — \(app.staticTexts.allElementsBoundByIndex.map(\.label))")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Burn mark' AND label CONTAINS 'new'")).firstMatch.exists, "an item the move-in did not have is new")
        try audit(app, "sealed move-out with changes")
        app.terminate()
    }
}
