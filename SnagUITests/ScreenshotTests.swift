// The README's screenshots, taken by the same flow the tests walk, so
// retaking the set is `make screenshots` and never a chore somebody skips.
// Skipped unless asked: TEST_RUNNER_SNAG_SCREENSHOTS=1. Each screen is an
// attachment; scripts/screenshots.sh pulls them out of the result bundle.
import XCTest

final class ScreenshotTests: XCTestCase {
    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    @MainActor
    func testTheSetForTheReadme() throws {
        guard ProcessInfo.processInfo.environment["SNAG_SCREENSHOTS"] == "1" else { throw XCTSkip("screenshots only when asked") }
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-freshStore", "-darkFixture"]
        app.launch()
        XCTAssertTrue(app.buttons["New report"].waitForExistence(timeout: 5))
        shot(app, "01-empty")
        app.buttons["New report"].tap()
        XCTAssertTrue(app.textViews["address"].waitForExistence(timeout: 3))
        choose(template: "Two bedroom", in: app)
        shot(app, "02-new-report")
        type("14 Admiralty Way, Lekki", into: app.textViews["address"], in: app)
        app.buttons["Walk the flat"].tap()
        XCTAssertTrue(app.staticTexts["14 Admiralty Way, Lekki"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["7 rooms"].waitForExistence(timeout: 3))
        shot(app, "03-walk")
        app.staticTexts["Kitchen"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Photograph"].waitForExistence(timeout: 3))
        shot(app, "04-room")
        app.buttons["Photograph"].tap()          // the dark fixture: the judge speaks
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        shot(app, "05-too-dark")
        app.buttons["Cancel"].tap()
        app.buttons["Tap"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.textViews["caption"].tap(); app.textViews["caption"].typeText("drips when closed")
        app.buttons["keyboardDone"].tap()
        shot(app, "06-item")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Tap — drips when closed"].waitForExistence(timeout: 3))
        app.buttons["Tiles"].tap()
        XCTAssertTrue(app.textViews["caption"].waitForExistence(timeout: 5))
        app.buttons["Fine"].tap(); app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Tiles"].waitForExistence(timeout: 3))
        shot(app, "07-room-with-items")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 3))
        app.buttons["Review"].tap()
        XCTAssertTrue(app.buttons["Seal"].waitForExistence(timeout: 3))
        shot(app, "08-review")
        app.buttons["Seal"].tap()
        XCTAssertTrue(app.staticTexts["Unaltered since signing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Share PDF"].waitForExistence(timeout: 5))
        shot(app, "09-sealed")
        app.terminate()

        let again = XCUIApplication()
        again.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-tamper"]
        again.launch()
        XCTAssertTrue(again.staticTexts["14 Admiralty Way, Lekki"].waitForExistence(timeout: 5))
        again.staticTexts["14 Admiralty Way, Lekki"].firstMatch.tap()
        XCTAssertTrue(again.staticTexts["Altered"].waitForExistence(timeout: 10))
        shot(again, "10-altered")
        again.terminate()

        let paper = XCUIApplication()
        paper.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-scanLatest"]
        paper.launch()
        // The tampered bundle's last room was empty, so the flipped byte broke
        // its decoding: it is listed as unreadable and the paper check says so.
        XCTAssertTrue(paper.staticTexts["Matches a report on this phone that can no longer be read"].waitForExistence(timeout: 10))
        XCTAssertTrue(paper.staticTexts["Altered"].exists)
        shot(paper, "11-paper-check")
        paper.terminate()
    }
}
