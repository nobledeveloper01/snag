// Backup and restore, and the seal nudge: proved without a screen.
import UserNotifications
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class DepthTests: XCTestCase {
    private func store() -> ReportStore { ReportStore(root: FileManager.default.temporaryDirectory.appendingPathComponent("depth-\(UUID().uuidString)")) }

    private func seal(_ store: ReportStore, address: String) throws -> ReportStore.Sealed {
        var d = store.newDraft(kind: .moveIn, address: address, now: 1_789_000_000)
        let photo = try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "fixture-2", withExtension: "jpg")))
        let h = store.store(photo: photo, in: d)
        d.report.rooms = [Room(name: .kitchen, items: [Item(state: .snag, photoHash: h, caption: address, takenAt: 1_789_000_100)])]
        store.update(d)
        return try store.seal(d, with: try Sealer())
    }

    func testABackupRestoresEveryBundleThatVerifiesAndRefusesTheRest() throws {
        let a = store()
        _ = try seal(a, address: "1 Backup Close")
        let second = try seal(a, address: "2 Backup Close")
        let url = try Backup.write(a)
        XCTAssertEqual(url.pathExtension, Backup.ext)
        let b = store()
        let r1 = try Backup.restore(try Data(contentsOf: url), into: b)
        XCTAssertEqual(r1.kept, 2); XCTAssertEqual(r1.refused, 0)
        XCTAssertEqual(b.sealed.map(\.report.address).sorted(), ["1 Backup Close", "2 Backup Close"])
        for s in b.sealed { guard case .unaltered = Verifier.verify(s.url) else { return XCTFail("restored bundle does not verify") } }
        // Again: nothing new, both refused as already here.
        let r2 = try Backup.restore(try Data(contentsOf: url), into: b)
        XCTAssertEqual(r2.kept, 0); XCTAssertEqual(r2.refused, 2)
        // One bundle tampered with inside the backup: kept 1, refused 1.
        try Data([0x01, 0x02, 0x03]).write(to: second.url.appendingPathComponent(SnagBundle.reportFile))
        let tampered = try Backup.write(a)
        let c = store()
        let r3 = try Backup.restore(try Data(contentsOf: tampered), into: c)
        XCTAssertEqual(r3.kept, 1); XCTAssertEqual(r3.refused, 1)
        XCTAssertEqual(c.sealed.map(\.report.address), ["1 Backup Close"])
    }

    func testTheSealNudgeIsScheduledForADraftAndCancelledAtTheSeal() async throws {
        Preferences.shared.nudge = true
        let s = store()
        var d = s.newDraft(kind: .moveIn, address: "3 Nudge Street", now: 1_789_000_000)
        try? await Task.sleep(for: .seconds(1))   // the scheduling task
        let pending = await SealNudge.pending()
        XCTAssertTrue(pending.contains("nudge." + d.id), "a note is pending for the draft: \(pending)")
        let photo = try Data(contentsOf: try XCTUnwrap(Bundle.main.url(forResource: "fixture-3", withExtension: "jpg")))
        let h = s.store(photo: photo, in: d)
        d.report.rooms = [Room(name: .kitchen, items: [Item(state: .fine, photoHash: h, caption: "", takenAt: 1)])]
        s.update(d)
        _ = try s.seal(d, with: try Sealer())
        let after = await SealNudge.pending()
        XCTAssertFalse(after.contains("nudge." + d.id), "sealed, the note is cancelled")
        // Off in the settings: nothing is scheduled.
        Preferences.shared.nudge = false
        let quiet = s.newDraft(kind: .moveIn, address: "4 Quiet Street", now: 1_789_000_000)
        try? await Task.sleep(for: .seconds(1))
        let none = await SealNudge.pending()
        XCTAssertFalse(none.contains("nudge." + quiet.id))
        Preferences.shared.nudge = true
    }
}
