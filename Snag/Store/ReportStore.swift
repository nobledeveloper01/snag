// Reports on disk. A draft is a directory under drafts/ holding the
// canonical bytes so far and its photographs by hash; sealing moves it to
// reports/<id>.snag with the signature and the key. The canonical bytes are
// the record in both places; there is no second format to drift.
import CryptoKit
import Foundation
import Observation
import SnagDomain

@MainActor
@Observable
final class ReportStore {
    struct Draft: Identifiable, Equatable {
        let id: String            // a directory name; never in the report
        var report: Report
    }
    struct Sealed: Identifiable, Equatable {
        let id: String            // the report id: hex of the digest
        let url: URL
        let report: Report
    }

    private(set) var drafts: [Draft] = []
    private(set) var sealed: [Sealed] = []
    let root: URL

    init(root: URL? = nil) {
        let base = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Snag")
        self.root = base
        try? FileManager.default.createDirectory(at: base.appendingPathComponent("drafts"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: base.appendingPathComponent("reports"), withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        let fm = FileManager.default
        drafts = ((try? fm.contentsOfDirectory(atPath: root.appendingPathComponent("drafts").path)) ?? []).sorted().compactMap { name in
            guard let data = try? Data(contentsOf: draftDir(name).appendingPathComponent("draft.bin")),
                  let r = try? Canonical.report(from: Array(data)) else { return nil }
            return Draft(id: name, report: r)
        }
        sealed = ((try? fm.contentsOfDirectory(atPath: root.appendingPathComponent("reports").path)) ?? []).sorted().compactMap { name in
            let url = root.appendingPathComponent("reports").appendingPathComponent(name)
            // Listed if it decodes, whatever the verifier will say: a bundle
            // that has gone bad on disk is shown as altered, not hidden.
            guard name.hasSuffix(".snag"),
                  let data = try? Data(contentsOf: url.appendingPathComponent(SnagBundle.reportFile)),
                  let r = try? Canonical.report(from: Array(data)) else { return nil }
            return Sealed(id: String(name.dropLast(5)), url: url, report: r)
        }
    }

    func draftDir(_ id: String) -> URL { root.appendingPathComponent("drafts").appendingPathComponent(id) }
    func photoURL(draft id: String, hash: [UInt8]) -> URL {
        draftDir(id).appendingPathComponent("photos").appendingPathComponent(SnagBundle.hex(hash) + ".jpg")
    }

    @discardableResult
    func newDraft(kind: Kind, address: String, now: Int64) -> Draft {
        let id = String(format: "%013d", now) + "-" + String(UInt32.random(in: 0...UInt32.max), radix: 36)
        let d = Draft(id: id, report: Report(kind: kind, address: address, createdAt: now))
        try? FileManager.default.createDirectory(at: draftDir(id).appendingPathComponent("photos"), withIntermediateDirectories: true)
        drafts.append(d)
        save(d)
        return d
    }

    func update(_ draft: Draft) {
        if let i = drafts.firstIndex(where: { $0.id == draft.id }) { drafts[i] = draft }
        save(draft)
    }

    private func save(_ d: Draft) {
        if let bytes = try? Canonical.bytes(of: d.report) {
            try? Data(bytes).write(to: draftDir(d.id).appendingPathComponent("draft.bin"))
        }
    }

    /// Hash at capture: the bytes are hashed before they are written, and
    /// the file is named by the hash. The domain stores the hash only.
    func store(photo data: Data, in draft: Draft) -> [UInt8] {
        let h = SnagBundle.sha256(data)
        try? data.write(to: photoURL(draft: draft.id, hash: h))
        return h
    }

    /// Seal: canonical bytes, digest, signature, bundle on disk, draft gone.
    func seal(_ draft: Draft, with sealer: Sealer) throws -> Sealed {
        let bytes = try Canonical.bytes(of: draft.report)
        let seal = try sealer.seal(bytes)
        let url = root.appendingPathComponent("reports").appendingPathComponent(seal.id + ".snag")
        var photos: [([UInt8], URL)] = []
        for room in draft.report.rooms {
            for item in room.items { photos.append((item.photoHash, photoURL(draft: draft.id, hash: item.photoHash))) }
            if let plan = room.planHash { photos.append((plan, photoURL(draft: draft.id, hash: plan))) }
        }
        try SnagBundle.write(report: bytes, seal: seal, photos: photos, to: url)
        try? FileManager.default.removeItem(at: draftDir(draft.id))
        drafts.removeAll { $0.id == draft.id }
        let s = Sealed(id: seal.id, url: url, report: draft.report)
        sealed.append(s)
        return s
    }

    func delete(sealed s: Sealed) {
        try? FileManager.default.removeItem(at: s.url)
        sealed.removeAll { $0.id == s.id }
    }
}
