// The measured tier: the tenant taps each corner of the floor through the
// camera, ARKit puts each tap on the floor plane, and the domain turns the
// corners into width, length and area at the centimetre. Four taps and a
// number, with the word *measured* beside it for ever.
//
// On a simulator there is no ARKit; the same screen takes its corners from
// a fixture, so everything after the sensor is proved. R1 is the sensor.
import ARKit
import SwiftUI
import SnagDomain

struct MeasureView: View {
    let done: ([Corner]) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var corners: [Corner] = []
    @State private var floorFound = false

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            ZStack {
                if Sensors.canMeasure {
                    ARFloorView(corners: $corners, floorFound: $floorFound).ignoresSafeArea()
                } else {
                    LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    // In a scroll view: the sentence is long and the largest
                    // text sizes need room to wrap past the card below.
                    ScrollView { VStack(spacing: Gap.m) {
                        Text(Strings.noSensor).font(Type.bodyFont()).foregroundStyle(palette.textSecondary).multilineTextAlignment(.center)
                        if Sensors.fixtures {
                            Button(Strings.fixtureCorners) { corners = ScannedFloor.tappedFixture }
                                .buttonStyle(Secondary(palette: palette))
                                .accessibilityIdentifier("fixtureCorners")
                        }
                    }
                    .padding(Gap.xl) }
                }
                VStack {
                    Spacer()
                    // What has been tapped so far, and what the taps make.
                    VStack(alignment: .leading, spacing: Gap.xs) {
                        Text(Sensors.canMeasure ? (floorFound ? Strings.measureHint : Strings.findingFloor) : Strings.measureHint)
                            .font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        Text("\(corners.count) \(Strings.corners)").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            .accessibilityIdentifier("cornerCount")
                        if let e = Floor.extents(corners, tier: .measured) {
                            Text(Dimensions.line(e.width, e.length, e.area)).font(Type.headlineFont()).foregroundStyle(palette.textPrimary)
                                .accessibilityIdentifier("dimensions")
                        }
                    }
                    .padding(Gap.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.raised.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.card))
                    .padding(.horizontal, Gap.l)
                }
            }
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.useMeasurement) { done(corners); dismiss() }
                        .buttonStyle(Primary(palette: palette))
                        .disabled(Floor.extents(corners, tier: .measured) == nil)
                        .accessibilityIdentifier("useMeasurement")
                    HStack(spacing: Gap.s) {
                        Button(Strings.undoCorner) { _ = corners.popLast() }.buttonStyle(Secondary(palette: palette)).disabled(corners.isEmpty)
                        Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                    }
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.measureRoom)
        }
        .tint(palette.accent)
    }
}

/// Numbers with their units, the way the app and the PDF say them.
enum Dimensions {
    static func line(_ w: Extent, _ l: Extent, _ a: Extent) -> String {
        "\(metres(w.centimetres)) × \(metres(l.centimetres)) m · \(squareMetres(a.centimetres)) m²"
    }
    static func metres(_ cm: Int32) -> String { String(format: "%.2f", Double(cm) / 100) }
    static func squareMetres(_ cm2: Int32) -> String { String(format: "%.1f", Double(cm2) / 10_000) }
}

/// The camera with the floor plane found, and a tap that becomes a corner.
struct ARFloorView: UIViewRepresentable {
    @Binding var corners: [Corner]
    @Binding var floorFound: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        view.session.delegate = context.coordinator
        view.session.run(config)
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:))))
        context.coordinator.view = view
        return view
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        let parent: ARFloorView
        weak var view: ARSCNView?
        init(_ parent: ARFloorView) { self.parent = parent }

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            let horizontal = anchors.contains { ($0 as? ARPlaneAnchor)?.alignment == .horizontal }
            guard horizontal else { return }
            Task { @MainActor in self.parent.floorFound = true }
        }

        /// A tap on the screen, cast onto the floor plane; the hit's x and z
        /// are the corner's x and y in metres on the floor.
        @objc func tap(_ g: UITapGestureRecognizer) {
            guard let view, let query = view.raycastQuery(from: g.location(in: view), allowing: .existingPlaneGeometry, alignment: .horizontal),
                  let hit = view.session.raycast(query).first else { return }
            let t = hit.worldTransform.columns.3
            parent.corners.append(Corner(x: Double(t.x), y: Double(t.z)))
        }
    }
}
