// The walk on the Lock Screen: the state the app sends, and that asking
// for it on a simulator that cannot show it does no harm.
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class ActivityTests: XCTestCase {
    func testTheStateIsTheReportsNumbersAndTheCallsAreSafeWithoutSupport() throws {
        let r = Report(kind: .moveIn, address: "5 Ikoyi Crescent", createdAt: 1_789_000_000, rooms: [
            Room(name: .kitchen, items: [Item(state: .snag, photoHash: Array(repeating: 1, count: 32), caption: "", takenAt: 1_789_000_100),
                                         Item(state: .fine, photoHash: Array(repeating: 2, count: 32), caption: "", takenAt: 1_789_000_400)]),
            Room(name: .bedroom),
        ])
        let state = WalkActivityAttributes.ContentState(rooms: r.rooms.count, items: r.itemCount, snags: r.snagCount, minutes: r.minutesWalked ?? 0)
        XCTAssertEqual(state, .init(rooms: 2, items: 2, snags: 1, minutes: 5))
        let encoded = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(WalkActivityAttributes.ContentState.self, from: encoded), state)
        // No Live Activities in a test host: show and end are no-ops that do not throw.
        WalkActivity.show(r)
        WalkActivity.show(r)
        WalkActivity.end()
    }
}
