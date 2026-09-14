// The picture and nothing but the picture, and the judge of it.
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import Snag

final class PhotoTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "jpg")))
    }

    func testStripLeavesNoLocationAndNoExif() throws {
        // A JPEG with GPS and EXIF written into it, the way a camera would.
        let base = try fixture("fixture-1")
        let src = try XCTUnwrap(CGImageSourceCreateWithData(base as CFData, nil))
        let out = NSMutableData()
        let dest = try XCTUnwrap(CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil))
        let props: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 6.4281, kCGImagePropertyGPSLongitude: 3.4219],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:09:14 01:00:00", kCGImagePropertyExifLensModel: "Test"],
        ]
        CGImageDestinationAddImageFromSource(dest, src, 0, props as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(dest))
        let tagged = out as Data
        XCTAssertTrue(Photo.metadataKeys(tagged).contains(kCGImagePropertyGPSDictionary as String), "the test photograph carries GPS before stripping")
        let stripped = try XCTUnwrap(Photo.strip(tagged))
        let keys = Photo.metadataKeys(stripped)
        XCTAssertFalse(keys.contains(kCGImagePropertyGPSDictionary as String), "no GPS after stripping")
        // The renderer writes a minimal EXIF block (pixel dimensions, colour
        // space) and nothing that says when, where or with what.
        let exif = Photo.metadata(stripped, kCGImagePropertyExifDictionary)
        for key in [kCGImagePropertyExifDateTimeOriginal, kCGImagePropertyExifLensModel, kCGImagePropertyExifUserComment, kCGImagePropertyExifSubsecTimeOriginal] {
            XCTAssertNil(exif[key as String], "\(key) is gone")
        }
        let tiff = Photo.metadata(stripped, kCGImagePropertyTIFFDictionary)
        for key in [kCGImagePropertyTIFFMake, kCGImagePropertyTIFFModel, kCGImagePropertyTIFFSoftware, kCGImagePropertyTIFFDateTime] {
            XCTAssertNil(tiff[key as String], "\(key) is gone")
        }
        XCTAssertNotNil(UIImage(data: stripped), "still a picture")
        XCTAssertEqual(UIImage(data: stripped)?.size.width, 1200, "same picture, same size")
    }

    func testTheJudgeSeesDarkAndBlurredAndPassesTheRest() throws {
        for name in ["fixture-1", "fixture-2", "fixture-3"] {
            XCTAssertEqual(Photo.judge(try fixture(name)), [], "\(name) is a fine photograph")
        }
        XCTAssertEqual(Photo.judge(try fixture("fixture-dark")), [.dark])
        XCTAssertEqual(Photo.judge(try fixture("fixture-blur")), [.blurred])
    }
}
