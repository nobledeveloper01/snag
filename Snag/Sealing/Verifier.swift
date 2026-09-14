// Opens a bundle and says one of two things: unaltered since signing, or
// altered. Needs the public key in the bundle and nothing else — not the
// phone, not the app that made it, not a network.
//
// Every photograph is checked twice: its content hashes to its filename,
// and its filename appears in the decoded report. The counter-signature
// layer, if present, is checked with the same key. Any failure is
// "altered"; there is no third answer, because a partial verdict is an
// invitation to argue about which part.
import CryptoKit
import Foundation
import SnagDomain

enum Verdict: Equatable, Sendable {
    case unaltered(Report, CounterSignature?)
    case altered(String)      // the first reason found, for the journal, never the screen
    case notABundle
}

enum Verifier {
    /// A bundle arrives as a folder or as one file. One file is unpacked
    /// beside the temporary directory and verified there; the directory
    /// that holds the photographs is returned with the verdict so a screen
    /// can show them.
    static func open(_ url: URL) -> (verdict: Verdict, dir: URL) {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue { return (verify(url), url) }
        guard let data = try? Data(contentsOf: url) else { return (.notABundle, url) }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("opened-" + url.deletingPathExtension().lastPathComponent + ".snag")
        try? FileManager.default.removeItem(at: dir)
        do { try ZipFile.extract(data, to: dir) } catch { return (.notABundle, url) }
        return (verify(dir), dir)
    }

    static func verify(_ dir: URL) -> Verdict {
        let fm = FileManager.default
        guard let reportData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.reportFile)),
              let sigData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.signatureFile)),
              let keyData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.keyFile)) else { return .notABundle }
        guard let key = try? P256.Signing.PublicKey(x963Representation: keyData) else { return .altered("public key") }
        guard let sig = try? P256.Signing.ECDSASignature(derRepresentation: sigData) else { return .altered("signature encoding") }
        let digest = SHA256.hash(data: reportData)
        guard key.isValidSignature(sig, for: digest) else { return .altered("report signature") }
        guard let report = try? Canonical.report(from: Array(reportData)) else { return .altered("report decoding") }

        // The amendment layer, if present: the same key, the original's id,
        // and a report that changes only the rooms' numbers. The report shown
        // is then the amended one; the original's seal stands underneath.
        var current = report
        if let aData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.amendmentFile)) {
            guard let aSigData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.amendmentSigFile)),
                  let aSig = try? P256.Signing.ECDSASignature(derRepresentation: aSigData),
                  key.isValidSignature(aSig, for: SHA256.hash(data: aData)) else { return .altered("amendment signature") }
            guard let a = try? Canonical.amendment(from: Array(aData)) else { return .altered("amendment decoding") }
            guard a.originalId == Array(digest) else { return .altered("amendment is for another report") }
            guard a.report.amendsOnlyNumbers(of: report) else { return .altered("amendment changes more than numbers") }
            current = a.report
        }

        // Every photograph either report names must be present and hash to its name.
        let photos = dir.appendingPathComponent(SnagBundle.photosDir)
        var named: Set<String> = []
        for room in report.rooms + current.rooms {
            for item in room.items { named.insert(SnagBundle.hex(item.photoHash)) }
            if let plan = room.planHash { named.insert(SnagBundle.hex(plan)) }
        }
        for h in named {
            guard let data = try? Data(contentsOf: photos.appendingPathComponent(h + ".jpg")) else { return .altered("photo missing \(h.prefix(8))") }
            guard SnagBundle.hex(SnagBundle.sha256(data)) == h else { return .altered("photo content \(h.prefix(8))") }
        }
        // And nothing else in photos/: a stray file is not the report that was signed.
        if let extra = try? fm.contentsOfDirectory(atPath: photos.path).filter({ !$0.hasPrefix(".") && !named.contains(String($0.dropLast(4))) }), !extra.isEmpty {
            return .altered("stray photo")
        }

        var counter: CounterSignature?
        if let cData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.counterFile)) {
            guard let cSigData = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.counterSigFile)),
                  let cSig = try? P256.Signing.ECDSASignature(derRepresentation: cSigData),
                  key.isValidSignature(cSig, for: SHA256.hash(data: cData)) else { return .altered("counter-signature") }
            guard let c = try? Canonical.counterSignature(from: Array(cData)) else { return .altered("counter-signature decoding") }
            guard c.reportId == Array(digest) else { return .altered("counter-signature is for another report") }
            // The drawn signature is bound the way a photograph is: present, and hashing to its name.
            guard let image = try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.signatureImage)) else { return .altered("signature image missing") }
            guard SnagBundle.sha256(image) == c.signatureHash else { return .altered("signature image") }
            counter = c
        }
        return .unaltered(current, counter)
    }

    /// The amendment layer alone, decoded, for the screens that say when.
    static func amendment(in dir: URL) -> Amendment? {
        (try? Data(contentsOf: dir.appendingPathComponent(SnagBundle.amendmentFile))).flatMap { try? Canonical.amendment(from: Array($0)) }
    }
}
