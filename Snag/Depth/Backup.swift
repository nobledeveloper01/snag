// Every sealed bundle in one file, to Files and back. A zip of the
// `.snag` directories; on the way back in each is verified before it is
// kept, so a backup that was tampered with restores nothing it cannot
// vouch for. Nothing leaves the phone except through the share sheet.
import Foundation
import SnagDomain

enum Backup {
    static let ext = "snagbackup"

    @MainActor
    static func write(_ store: ReportStore) throws -> URL {
        var entries: [ZipFile.Entry] = []
        for s in store.sealed {
            let dir = s.url
            guard let walker = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey]) else { continue }
            for case let url as URL in walker where (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                let rel = url.path.replacingOccurrences(of: dir.deletingLastPathComponent().path + "/", with: "")
                entries.append(ZipFile.Entry(name: rel, data: try Data(contentsOf: url)))
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Snag-backup-\(Int(Date().timeIntervalSince1970)).\(ext)")
        try ZipFile.archive(entries.sorted { $0.name < $1.name }).write(to: url)
        return url
    }

    /// Restores every bundle that verifies; returns (kept, refused).
    @MainActor
    static func restore(_ data: Data, into store: ReportStore) throws -> (kept: Int, refused: Int) {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("restore-\(UUID().uuidString)")
        try ZipFile.extract(data, to: tmp)
        var kept = 0, refused = 0
        for name in (try? FileManager.default.contentsOfDirectory(atPath: tmp.path)) ?? [] where name.hasSuffix(".snag") {
            let src = tmp.appendingPathComponent(name)
            let dst = store.root.appendingPathComponent("reports").appendingPathComponent(name)
            guard case .unaltered = Verifier.verify(src), !FileManager.default.fileExists(atPath: dst.path) else { refused += 1; continue }
            try FileManager.default.copyItem(at: src, to: dst)
            kept += 1
        }
        try? FileManager.default.removeItem(at: tmp)
        store.reload()
        return (kept, refused)
    }
}
