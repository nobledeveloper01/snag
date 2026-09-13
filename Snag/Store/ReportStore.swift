// Drafts, in memory for Phase 0. Phase 1 puts sealed reports on disk, one
// directory per report id, with the canonical bytes as the record.
import Observation
import SnagDomain

@MainActor
@Observable
final class ReportStore {
    private(set) var drafts: [Draft] = []

    struct Draft: Identifiable {
        let id: Int
        var report: Report
    }

    private var next = 1

    @discardableResult
    func newDraft(kind: Kind, address: String, now: Int64) -> Draft {
        let d = Draft(id: next, report: Report(kind: kind, address: address, createdAt: now))
        next += 1
        drafts.append(d)
        return d
    }

    func update(_ draft: Draft) {
        if let i = drafts.firstIndex(where: { $0.id == draft.id }) { drafts[i] = draft }
    }
}
