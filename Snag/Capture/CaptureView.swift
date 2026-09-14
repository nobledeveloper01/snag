// The viewfinder, on a phone with a camera: the live preview, the torch,
// the shutter at 64 points, one hand. The simulator never shows this —
// its shutter goes straight to the fixture — so the screen is proved by
// the same ItemSheet flow that follows it and by R1's handset.
import AVFoundation
import SwiftUI

struct CaptureView: View {
    let camera: CameraPhotos
    let prompt: String?
    let done: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var busy = false
    @State private var torchOn = Torch.isOn

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            CameraPreview(session: camera.session).ignoresSafeArea()
            VStack {
                if let prompt {
                    Text(prompt).font(Type.headlineFont()).foregroundStyle(palette.onAccent)
                        .padding(Gap.m).background(palette.accent.opacity(0.9), in: RoundedRectangle(cornerRadius: Radius.card))
                        .padding(.top, Gap.l)
                }
                Spacer()
            }
        }
        .pinned {
            HStack(spacing: Gap.s) {
                Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette)).frame(width: 100)
                Button {
                    guard !busy else { return }
                    busy = true
                    Task {
                        if let data = await camera.capture() { done(data) }
                        busy = false
                        dismiss()
                    }
                } label: {
                    Label(Strings.takePhoto, systemImage: "camera.fill")
                }
                .buttonStyle(Primary(palette: palette)).disabled(busy)
                if Torch.available {
                    Button {
                        Torch.toggle(); torchOn = Torch.isOn
                    } label: {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill").font(.title2)
                            .foregroundStyle(torchOn ? palette.onAccent : palette.textPrimary)
                            .frame(width: Target.primary, height: Target.primary)
                            .background(torchOn ? palette.accent : palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
                    }
                    .accessibilityLabel(Strings.torch).accessibilityValue(torchOn ? Strings.on : Strings.off)
                }
            }
            .padding(Gap.l)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.layer.session = session
        v.layer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        override var layer: AVCaptureVideoPreviewLayer { super.layer as! AVCaptureVideoPreviewLayer }
    }
}
