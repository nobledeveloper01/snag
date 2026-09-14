// The tenant's own iCloud, and only theirs: every sealed bundle mirrored to
// the private CloudKit database as one file, and back to the tenant's other
// devices — each bundle verified before it is kept, as a backup is. There
// is still no server of ours; Apple holds the tenant's bytes under the
// tenant's Apple ID, which is the one place the product statement lets
// them go. Off by default. ADR-0005.
//
// The CloudKit half is the only code in the app that imports CloudKit, and
// `network-check` says so. The mirror itself is written against a protocol
// so it is proved with a store in memory; CloudKit's own behaviour is
// proved on a signed-in phone, which the ledger's R6 waits for.
import CloudKit
import Foundation
import SnagDomain

/// What a cloud store has to be: files by report id, each with the layers
/// it carries — "" for the seal alone, "c" with a counter-signature, "a"
/// with an amendment, "ac" with both.
protocol CloudStore: Sendable {
    func list() async throws -> [String: String]
    func fetch(_ id: String) async throws -> Data?
    func put(_ id: String, layers: String, data: Data) async throws
}

enum CloudMirror {
    struct Outcome: Equatable { var pushed = 0, pulled = 0, refused = 0 }

    /// The layers a bundle on disk carries, as the mirror names them.
    static func layers(of dir: URL) -> String {
        let fm = FileManager.default
        return (fm.fileExists(atPath: dir.appendingPathComponent(SnagBundle.amendmentFile).path) ? "a" : "") +
               (fm.fileExists(atPath: dir.appendingPathComponent(SnagBundle.counterFile).path) ? "c" : "")
    }

    /// Push what the cloud lacks, pull what this phone lacks, verify what
    /// comes down. A bundle that fails verification is refused and counted.
    @MainActor
    static func sync(_ store: ReportStore, with cloud: CloudStore) async throws -> Outcome {
        var out = Outcome()
        let remote = try await cloud.list()
        let local = Dictionary(uniqueKeysWithValues: store.sealed.map { ($0.id, $0.url) })
        for (id, url) in local {
            let mine = layers(of: url)
            let theirs = remote[id]
            // Up when the cloud has never seen it, or has fewer layers.
            if theirs == nil || (theirs!.count < mine.count) {
                try await cloud.put(id, layers: mine, data: try ZipFile.archive(directory: url))
                out.pushed += 1
            }
        }
        for (id, theirs) in remote {
            let mine = local[id].map(layers(of:))
            guard mine == nil || theirs.count > mine!.count, let data = try await cloud.fetch(id) else { continue }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("cloud-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tmp) }
            do { try ZipFile.extract(data, to: tmp) } catch { out.refused += 1; continue }
            guard case .unaltered = Verifier.verify(tmp), (try? Data(contentsOf: tmp.appendingPathComponent(SnagBundle.reportFile))).map({ SnagBundle.hex(SnagBundle.sha256($0)) }) == id else {
                out.refused += 1; continue
            }
            let dst = store.root.appendingPathComponent("reports").appendingPathComponent(id + ".snag")
            try? FileManager.default.removeItem(at: dst)
            try FileManager.default.copyItem(at: tmp, to: dst)
            out.pulled += 1
        }
        if out.pulled > 0 { store.reload() }
        return out
    }
}

/// A store in memory, for the tests and for a phone with no iCloud.
actor MemoryCloud: CloudStore {
    private var files: [String: (layers: String, data: Data)] = [:]
    func list() async throws -> [String: String] { files.mapValues(\.layers) }
    func fetch(_ id: String) async throws -> Data? { files[id]?.data }
    func put(_ id: String, layers: String, data: Data) async throws { files[id] = (layers, data) }
    /// For the tests: what a tamperer or a stale device would leave behind.
    func overwrite(_ id: String, layers: String, data: Data) { files[id] = (layers, data) }
}

/// CloudKit's private database: one record per bundle, the file as an asset.
struct PrivateCloud: CloudStore {
    static let recordType = "Bundle"
    private var database: CKDatabase { CKContainer.default().privateCloudDatabase }

    static func available() async -> Bool {
        ((try? await CKContainer.default().accountStatus()) ?? .noAccount) == .available
    }

    func list() async throws -> [String: String] {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        var out: [String: String] = [:]
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let page: (matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)], queryCursor: CKQueryOperation.Cursor?)
            if let cursor {
                page = try await database.records(continuingMatchFrom: cursor, desiredKeys: ["layers"])
            } else {
                page = try await database.records(matching: query, desiredKeys: ["layers"])
            }
            for (id, result) in page.matchResults {
                if let record = try? result.get() { out[id.recordName] = record["layers"] as? String ?? "" }
            }
            cursor = page.queryCursor
        } while cursor != nil
        return out
    }

    func fetch(_ id: String) async throws -> Data? {
        let record = try await database.record(for: CKRecord.ID(recordName: id))
        guard let asset = record["file"] as? CKAsset, let url = asset.fileURL else { return nil }
        return try Data(contentsOf: url)
    }

    func put(_ id: String, layers: String, data: Data) async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(id).snagz")
        try data.write(to: tmp)
        let record = (try? await database.record(for: CKRecord.ID(recordName: id))) ?? CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["layers"] = layers as CKRecordValue
        record["file"] = CKAsset(fileURL: tmp)
        _ = try await database.save(record)
    }
}
