// The scanned tier: RoomPlan on a LiDAR phone. The tenant walks the room
// with the camera up; when the room closes, the floor polygon and the
// walls become a `ScannedFloor`, the domain gives the numbers, and the
// plan is drawn and hashed into the bundle. R2 is the sensor; on the
// simulator the fixture room stands in.
import RoomPlan
import simd
import SwiftUI
import SnagDomain

struct ScanView: View {
    let done: (ScannedFloor) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var floor: ScannedFloor?
    @State private var scanning = false

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            ZStack {
                if Sensors.canScan {
                    RoomScanView(floor: $floor, scanning: $scanning).ignoresSafeArea()
                } else {
                    LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    // In a scroll view: the sentence is long and the largest
                    // text sizes need room to wrap past the card below.
                    ScrollView { VStack(spacing: Gap.m) {
                        Text(Strings.noSensor).font(Type.bodyFont()).foregroundStyle(palette.textSecondary).multilineTextAlignment(.center)
                        if Sensors.fixtures {
                            Button(Strings.fixtureCorners) { floor = ScannedFloor.fixture }
                                .buttonStyle(Secondary(palette: palette))
                                .accessibilityIdentifier("fixtureScan")
                        }
                    }
                    .padding(Gap.xl) }
                }
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: Gap.xs) {
                        Text(floor == nil ? (Sensors.canScan ? Strings.scanHint : Strings.scanHint) : Strings.scanDone)
                            .font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        if let floor, let e = Floor.extents(floor.corners, tier: .scanned) {
                            Text(Dimensions.line(e.width, e.length, e.area)).font(Type.headlineFont()).foregroundStyle(palette.textPrimary)
                                .accessibilityIdentifier("dimensions")
                            if let data = PlanRenderer.jpeg(floor, label: ""), let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
                                    .accessibilityLabel(Strings.plan)
                            }
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
                    Button(Strings.useScan) { if let floor { done(floor) }; dismiss() }
                        .buttonStyle(Primary(palette: palette))
                        .disabled(floor.map { Floor.extents($0.corners, tier: .scanned) == nil } ?? true)
                        .accessibilityIdentifier("useScan")
                    Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.scanRoom)
        }
        .tint(palette.accent)
    }
}

/// RoomPlan's own capture view; when the session ends, the captured room's
/// floor and walls, projected onto the floor plane, become a ScannedFloor.
struct RoomScanView: UIViewRepresentable {
    @Binding var floor: ScannedFloor?
    @Binding var scanning: Bool

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.delegate = context.coordinator
        view.captureSession.delegate = context.coordinator
        view.captureSession.run(configuration: RoomCaptureSession.Configuration())
        return view
    }
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    @objc(SnagRoomScanCoordinator)
    final class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        let parent: RoomScanView
        init(_ parent: RoomScanView) { self.parent = parent }

        nonisolated func encode(with coder: NSCoder) {}
        nonisolated required init?(coder: NSCoder) { nil }

        nonisolated func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool { true }

        nonisolated func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            let floor = Self.floor(of: processedResult)
            Task { @MainActor in self.parent.floor = floor }
        }

        /// The floor polygon from the first floor surface; walls and openings
        /// from their transforms — each surface is a rectangle in its own
        /// frame, and its bottom edge on the floor is what the plan draws.
        nonisolated static func floor(of room: CapturedRoom) -> ScannedFloor? {
            func edge(_ s: CapturedRoom.Surface) -> (Corner, Corner) {
                let half = s.dimensions.x / 2
                let a = simd_mul(s.transform, SIMD4<Float>(-half, 0, 0, 1)), b = simd_mul(s.transform, SIMD4<Float>(half, 0, 0, 1))
                return (Corner(x: Double(a.x), y: Double(a.z)), Corner(x: Double(b.x), y: Double(b.z)))
            }
            let corners: [Corner]
            if let f = room.floors.first, !f.polygonCorners.isEmpty {
                corners = f.polygonCorners.map { Corner(x: Double($0.x), y: Double($0.z)) }
            } else {
                corners = room.walls.map { edge($0).0 }
            }
            guard corners.count >= 3 else { return nil }
            return ScannedFloor(corners: corners, walls: room.walls.map(edge), openings: (room.doors + room.windows + room.openings).map(edge))
        }
    }
}
