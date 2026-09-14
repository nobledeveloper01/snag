// The bundled face is the face on screen. A wrong font name falls back to
// the system face without a word, so the name is asserted here.
import XCTest
@testable import Snag

final class TypeTests: XCTestCase {
    func testInterIsBundledRegisteredAndNamedCorrectly() throws {
        let font = try XCTUnwrap(UIFont(name: Type.family, size: 17), "UIFont does not know '\(Type.family)'; the families it knows with Inter in the name: \(UIFont.familyNames.filter { $0.contains("Inter") })")
        XCTAssertTrue(font.familyName.hasPrefix("Inter"), font.familyName)
    }
}
