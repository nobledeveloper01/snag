// A printed report, matched to a bundle on this phone. The cover's QR
// carries the id and the key's fingerprint; the camera reads it, or the
// tenant types it, and the screen says whether a bundle with that id is
// here and still verifies. It does not say the paper is true — paper can
// be printed from anything — only that it names a bundle this phone holds.
import AVFoundation
import SwiftUI
import SnagDomain

struct CheckPaperView: View {
    @Bindable var store: ReportStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var typed = ""
    @State private var result: Result?

    enum Result: Equatable {
        case matches(ReportStore.Sealed, Verdict)
        case matchesBroken(URL)
        case keyDiffers(ReportStore.Sealed)
        case notHere
        case notACode
    }

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            // A ScrollView of cards, not a List: a List presented in this sheet
            // kept drawing its first layout on the simulator while the
            // accessibility tree — and the tests — saw the answer. The item
            // sheet is built this way and has never done that.
            ScrollView {
                VStack(alignment: .leading, spacing: Gap.m) {
                    if Scanner.available {
                        Scanner { check($0) }
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                            .accessibilityLabel(Strings.scanner)
                    }
                    Text(Strings.checkPaperHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                    Text(Strings.codeSays).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    TextEditor(text: $typed)
                        .font(Type.bodyFont())
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: Target.standard)
                        .padding(Gap.s)
                        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.tile))
                        .accessibilityLabel(Strings.codeSays).accessibilityIdentifier("code")
                    if let result {
                        VStack(alignment: .leading, spacing: Gap.s) {
                            switch result {
                            case .matches(let s, let v):
                                Text("\(Strings.matches) \(s.report.address)").font(Type.headlineFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                                VerdictRow(verdict: v, palette: palette)
                            case .matchesBroken:
                                Text(Strings.matchesBroken).font(Type.headlineFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                                VerdictRow(verdict: .altered("unreadable"), palette: palette)
                            case .keyDiffers(let s):
                                Text("\(Strings.matches) \(s.report.address)").font(Type.headlineFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                                Text(Strings.keyDiffers).font(Type.bodyFont()).foregroundStyle(palette.snag).frame(minHeight: Target.standard)
                            case .notHere:
                                Text(Strings.notHere).font(Type.bodyFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                            case .notACode:
                                Text(Strings.notACode).font(Type.bodyFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                            }
                        }
                        .padding(Gap.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
                        .accessibilityIdentifier("result")
                    }
                }
                .padding(Gap.l)
            }
            .scrollDismissesKeyboard(.immediately)
            .pinned {
                // Check is pinned, so the keyboard never covers it.
                VStack(spacing: Gap.s) {
                    Button(Strings.check) { check(typed) }
                        .buttonStyle(Primary(palette: palette))
                        .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(Strings.done) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.checkPaper)
        }
        .tint(palette.accent)
        .task {
            // -scanLatest: the UI test's stand-in for the camera reading the
            // cover of the latest sealed report.
            guard CommandLine.arguments.contains("-scanLatest"), let url = store.latestBundle,
                  let key = try? Data(contentsOf: url.appendingPathComponent(SnagBundle.keyFile)) else { return }
            typed = ReportPDF.qrPayload(id: url.deletingPathExtension().lastPathComponent, publicKey: Array(key))
            check(typed)
        }
    }

    /// `snag:1:<id>:<fingerprint>` → a bundle here, or not.
    private func check(_ text: String) {
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":").map(String.init)
        guard parts.count == 4, parts[0] == "snag", parts[1] == "1", parts[2].count == 64 else { result = .notACode; return }
        guard let s = store.sealed.first(where: { $0.id == parts[2] }) else {
            result = store.broken.contains { $0.deletingPathExtension().lastPathComponent == parts[2] } ? .matchesBroken(store.broken.first { $0.deletingPathExtension().lastPathComponent == parts[2] }!) : .notHere
            return
        }
        let key = (try? Data(contentsOf: s.url.appendingPathComponent(SnagBundle.keyFile))).map(Array.init) ?? []
        guard ReportPDF.qrPayload(id: s.id, publicKey: key) == "snag:1:\(parts[2]):\(parts[3])" else { result = .keyDiffers(s); return }
        result = .matches(s, Verifier.verify(s.url))
    }
}

/// The camera, reading QR codes. Only where there is one.
struct Scanner: UIViewRepresentable {
    let found: (String) -> Void
    static var available: Bool { AVCaptureDevice.default(for: .video) != nil }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
        }
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        view.layer.session = session
        let box = Box(session: session)
        DispatchQueue.global(qos: .userInitiated).async { box.session.startRunning() }
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(found: found) }

    private struct Box: @unchecked Sendable { let session: AVCaptureSession }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        override var layer: AVCaptureVideoPreviewLayer { super.layer as! AVCaptureVideoPreviewLayer }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let found: (String) -> Void
        init(found: @escaping (String) -> Void) { self.found = found }
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let code = (objects.first as? AVMetadataMachineReadableCodeObject)?.stringValue { found(code) }
        }
    }
}
