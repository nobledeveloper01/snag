// The real camera: one still per tap, as JPEG. Configured once; the
// preview is the CaptureView's. Hashing happens in the store, not here.
import AVFoundation
import Foundation

@MainActor
final class CameraPhotos: NSObject, PhotoSource, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<Data?, Never>?
    var hasCamera: Bool { true }
    private struct Box: @unchecked Sendable { let session: AVCaptureSession }

    override init() {
        super.init()
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        // startRunning blocks, so it goes off the main actor; the session
        // is handed across in a box because AVFoundation has not marked it.
        let box = Box(session: session)
        DispatchQueue.global(qos: .userInitiated).async { box.session.startRunning() }
    }

    func capture() async -> Data? {
        await withCheckedContinuation { c in
            continuation = c
            output.capturePhoto(with: AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg]), delegate: self)
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in self.continuation?.resume(returning: data); self.continuation = nil }
    }
}
