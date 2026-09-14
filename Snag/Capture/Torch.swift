// The design floor is a flat with the power off. The torch is the camera's
// own LED, toggled beside the shutter; absent where the phone has none,
// which includes the simulator.
import AVFoundation

@MainActor
enum Torch {
    static var available: Bool { AVCaptureDevice.default(for: .video)?.hasTorch ?? false }
    static var isOn: Bool { AVCaptureDevice.default(for: .video)?.torchMode == .on }

    static func toggle() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch,
              (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }
}
