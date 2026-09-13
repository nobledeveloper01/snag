import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class StoreTests: XCTestCase {
    func testADraftIsMadeAndUpdated() {
        let store = ReportStore()
        var d = store.newDraft(kind: .moveIn, address: "14 Admiralty Way", now: 1_789_000_000)
        XCTAssertEqual(store.drafts.count, 1)
        d.report.rooms.append(Room(name: .kitchen))
        store.update(d)
        XCTAssertEqual(store.drafts[0].report.rooms.count, 1)
        XCTAssertEqual(store.drafts[0].report.tier, .photographed)
    }

    func testTheClockCanBePinnedForTests() {
        // -now is not in this process's arguments; the real clock is recent.
        XCTAssertGreaterThan(Clock.now(), 1_700_000_000)
    }
}
