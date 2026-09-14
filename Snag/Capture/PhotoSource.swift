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
    private var last: Data?
    var hasCamera: Bool { false }
    /// Every shot is a different photograph — the shot number is drawn into
    /// it — so a walk of any length never repeats a hash by accident. With
    /// `-repeatFixture` the second shot is the first again, on purpose, so
    /// the duplicate rule can be seen refusing it.
    func capture() async -> Data? {
        if CommandLine.arguments.contains("-repeatFixture"), next == 2, let last { next += 1; return last }
        // -darkFixture: the first shot is the dark one, so the judge's answer
        // can be read off a screen.
        var name = "fixture-\((next - 1) % 3 + 1)"
        if CommandLine.arguments.contains("-darkFixture"), next == 1 { name = "fixture-dark" }
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"), let base = UIImage(contentsOfFile: url.path) else { return nil }
        let shot = next
        next += 1
        // The shot number as a row of squares, not as text: the audit reads
        // text in a picture as text that should be an element.
        let data = UIGraphicsImageRenderer(size: base.size).jpegData(withCompressionQuality: 0.8) { ctx in
            base.draw(at: .zero)
            UIColor.white.setFill()
            for i in 0..<shot { ctx.fill(CGRect(x: 40 + i * 30, y: 40, width: 20, height: 20)) }
        }
        last = data
        return data
    }
}

@MainActor
enum PhotoSources {
    /// One source for the whole app: the camera session is configured once,
    /// and the fixture's shot counter runs across rooms, so the same fixture
    /// never lands twice by accident.
    static let shared: PhotoSource = {
        if CommandLine.arguments.contains("-fixturePhotos") || AVCaptureDevice.default(for: .video) == nil { return FixturePhotos() }
        return CameraPhotos()
    }()
}
