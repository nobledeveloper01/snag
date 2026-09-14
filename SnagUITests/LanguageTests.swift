// Five languages, chosen in the app: the picker in Settings, the empty
// state read in Naijá, the choice surviving a relaunch, and every language
// audited on the screen most tenants see first.
import XCTest

final class LanguageTests: XCTestCase {
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
    func testTheLanguageIsChosenInSettingsAndKept() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-now", "1789000000", "-fixturePhotos", "-freshStore"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Start with the flat you're standing in."].waitForExistence(timeout: 5))
        let titles = [
            "lang-pcm": "Start with the flat wey you dey stand inside.",
            "lang-yo": "Bẹ̀rẹ̀ pẹ̀lú ilé tí o dúró sí.",
            "lang-ha": "Fara da gidan da kake tsaye a ciki.",
            "lang-ig": "Bido n'ụlọ ị guzo n'ime ya.",
        ]
        for row in ["lang-pcm", "lang-yo", "lang-ha", "lang-ig"] {
            let title = titles[row]!
            app.buttons["settings"].tap()
            XCTAssertTrue(app.buttons[row].waitForExistence(timeout: 3))
            app.buttons[row].tap()
            if row == "lang-pcm" { try audit(app, "settings in Naijá") }
            app.buttons["settingsDone"].tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3), "the empty state in \(row)")
            try audit(app, "empty state in \(row)")
        }
        app.terminate()

        // Kept across a launch, and back to English from Igbo.
        let again = XCUIApplication()
        again.launchArguments = ["-now", "1789000000", "-fixturePhotos"]
        again.launch()
        XCTAssertTrue(again.staticTexts["Bido n'ụlọ ị guzo n'ime ya."].waitForExistence(timeout: 5), "the language survives a relaunch")
        again.buttons["settings"].tap()
        XCTAssertTrue(again.buttons["lang-en"].waitForExistence(timeout: 3))
        again.buttons["lang-en"].tap()
        again.buttons["settingsDone"].tap()
        XCTAssertTrue(again.staticTexts["Start with the flat you're standing in."].waitForExistence(timeout: 3))
        again.terminate()
    }
}
