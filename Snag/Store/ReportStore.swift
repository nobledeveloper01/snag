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
        var counter: CounterSignature?
        var idBytes: [UInt8] { stride(from: 0, to: id.count, by: 2).compactMap { i in UInt8(id[id.index(id.startIndex, offsetBy: i)..<id.index(id.startIndex, offsetBy: i + 2)], radix: 16) } }
    }

    /// Where the walk was when the app went away: a draft and a room. Set
    /// when a room is opened, cleared when the walk is left on purpose.
    var resume: (draft: String, room: Int)? {
        get {
            guard let d = UserDefaults.standard.string(forKey: "resume.draft") else { return nil }
            return (d, UserDefaults.standard.integer(forKey: "resume.room"))
        }
        set {
            UserDefaults.standard.set(newValue?.draft, forKey: "resume.draft")
            UserDefaults.standard.set(newValue?.room ?? 0, forKey: "resume.room")
        }
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
            let counter = (try? Data(contentsOf: url.appendingPathComponent(SnagBundle.counterFile))).flatMap { try? Canonical.counterSignature(from: Array($0)) }
            return Sealed(id: String(name.dropLast(5)), url: url, report: r, counter: counter)
        }
    }

    func draftDir(_ id: String) -> URL { root.appendingPathComponent("drafts").appendingPathComponent(id) }
    func photoURL(draft id: String, hash: [UInt8]) -> URL {
        draftDir(id).appendingPathComponent("photos").appendingPathComponent(SnagBundle.hex(hash) + ".jpg")
    }

    @discardableResult
    /// A move-out linked to a move-in starts with the move-in's rooms, in
    /// its order, empty — so the same view can be shot in each.
    func newDraft(kind: Kind, address: String, now: Int64, template: RoomTemplate? = nil, movedIn: Sealed? = nil) -> Draft {
        let id = String(format: "%013d", now) + "-" + String(UInt32.random(in: 0...UInt32.max), radix: 36)
        let rooms = movedIn.map { $0.report.rooms.map { Room(name: $0.name, custom: $0.custom) } } ?? (template?.rooms ?? []).map { Room(name: $0) }
        let d = Draft(id: id, report: Report(kind: kind, address: address, createdAt: now, movedInReportId: movedIn?.idBytes, rooms: rooms))
        try? FileManager.default.createDirectory(at: draftDir(id).appendingPathComponent("photos"), withIntermediateDirectories: true)
        drafts.append(d)
        save(d)
        Task { await SealNudge.schedule(draft: id, address: address) }
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
        if resume?.draft == draft.id { resume = nil }
        SealNudge.cancel(draft: draft.id)
        let s = Sealed(id: seal.id, url: url, report: draft.report)
        sealed.append(s)
        return s
    }

    /// The sealed move-in a report points at, if it is on this phone.
    func movedIn(for report: Report) -> Sealed? {
        guard let id = report.movedInReportId else { return nil }
        return sealed.first { $0.idBytes == id }
    }

    /// The other party's signature, as the second layer the format has:
    /// name, phone, the drawn signature as a picture, signed with the same key.
    func counterSign(_ s: Sealed, name: String, phone: String, signature image: Data, with sealer: Sealer, now: Int64) throws -> Sealed {
        let c = CounterSignature(reportId: s.idBytes, name: name, phone: phone, signatureHash: SnagBundle.sha256(image), signedAt: now)
        let bytes = try Canonical.bytes(of: c)
        try SnagBundle.writeCounterSignature(bytes, seal: try sealer.seal(bytes), signature: image, to: s.url)
        var updated = s
        updated.counter = c
        if let i = sealed.firstIndex(where: { $0.id == s.id }) { sealed[i] = updated }
        return updated
    }

    func delete(draft d: Draft) {
        try? FileManager.default.removeItem(at: draftDir(d.id))
        drafts.removeAll { $0.id == d.id }
        SealNudge.cancel(draft: d.id)
        if resume?.draft == d.id { resume = nil }
    }

    func delete(sealed s: Sealed) {
        try? FileManager.default.removeItem(at: s.url)
        sealed.removeAll { $0.id == s.id }
    }
}
