// Where a floor's corners come from. ARKit on a phone: the tenant taps each
// corner and a raycast onto the detected floor plane gives a point in
// metres. RoomPlan on a LiDAR phone: the scan's floor polygon. And on the
// simulator, which has neither, a fixture — so the domain arithmetic, the
// room's tier, the PDF and the verifier are exercised where only the
// sensors wait for a handset (R1, R2).
import ARKit
import Foundation
import RoomPlan
import SnagDomain

@MainActor
enum Sensors {
    /// ARKit world tracking with plane detection: A12 and later. Never on a simulator.
    static var canMeasure: Bool { ARWorldTrackingConfiguration.isSupported }
    /// RoomPlan: LiDAR. Never on a simulator.
    static var canScan: Bool { RoomCaptureSession.isSupported }
    static var fixtures: Bool { CommandLine.arguments.contains("-fixtureFloors") }
}

/// A floor the way the app keeps it between the sensor and the domain:
/// corners in metres on the floor plane, and the walls the scanner drew,
/// if it was a scanner. The plan image is made from this, not from
/// RoomPlan's own types, so a fixture can make one too.
struct ScannedFloor: Equatable {
    var corners: [Corner]
    var walls: [(Corner, Corner)]
    var openings: [(Corner, Corner)]     // doors and windows, as gaps in the walls

    static func == (a: ScannedFloor, b: ScannedFloor) -> Bool {
        a.corners == b.corners && a.walls.map { [$0.0, $0.1] } == b.walls.map { [$0.0, $0.1] } && a.openings.map { [$0.0, $0.1] } == b.openings.map { [$0.0, $0.1] }
    }

    /// The fixture: a 3.6 × 4.2 m room with a door on one side and a window on another.
    static let fixture = ScannedFloor(
        corners: [Corner(x: 0, y: 0), Corner(x: 3.6, y: 0), Corner(x: 3.6, y: 4.2), Corner(x: 0, y: 4.2)],
        walls: [(Corner(x: 0, y: 0), Corner(x: 3.6, y: 0)), (Corner(x: 3.6, y: 0), Corner(x: 3.6, y: 4.2)),
                (Corner(x: 3.6, y: 4.2), Corner(x: 0, y: 4.2)), (Corner(x: 0, y: 4.2), Corner(x: 0, y: 0))],
        openings: [(Corner(x: 1.2, y: 0), Corner(x: 2.1, y: 0)), (Corner(x: 3.6, y: 1.5), Corner(x: 3.6, y: 2.7))])

    /// The fixture for tapped corners: the same room, tapped slightly unevenly,
    /// the way a person does.
    static let tappedFixture = [Corner(x: 0.02, y: -0.01), Corner(x: 3.58, y: 0.03), Corner(x: 3.61, y: 4.19), Corner(x: -0.02, y: 4.22)]
}
