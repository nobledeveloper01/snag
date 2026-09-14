// Where a photograph comes from. The camera on a phone; on the simulator,
// which has no camera, a bundled fixture — so the walk, the hashing, the
// seal, the PDF and the verifier are all exercised where only the sensor
// waits for hardware.
import AVFoundation
import Foundation
import UIKit

@MainActor
protocol PhotoSource: AnyObject {
    var hasCamera: Bool { get }
    /// JPEG bytes. Hashed by the store the moment they arrive.
    func capture() async -> Data?
}

@MainActor
final class FixturePhotos: PhotoSource {
    private var next = 1
    var hasCamera: Bool { false }
    func capture() async -> Data? {
        let name = "fixture-\((next - 1) % 3 + 1)"
        next += 1
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else { return nil }
        return try? Data(contentsOf: url)
    }
}

@MainActor
enum PhotoSources {
    static func make() -> PhotoSource {
        if CommandLine.arguments.contains("-fixturePhotos") || AVCaptureDevice.default(for: .video) == nil { return FixturePhotos() }
        return CameraPhotos()
    }
}
