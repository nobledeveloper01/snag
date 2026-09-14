// The bundle on disk: `<id>.snag/`, a directory package. Nothing but the
// canonical bytes, the signature, the public key, the photographs by hash,
// and — if present — the counter-signature layer. docs/BUNDLE-FORMAT.md is
// the spec.
import CryptoKit
import Foundation
import SnagDomain

enum SnagBundle {
    static let reportFile = "report.bin"
    static let signatureFile = "report.sig"
    static let keyFile = "key.pub"
    static let photosDir = "photos"
    static let counterFile = "countersign.bin"
    static let counterSigFile = "countersign.sig"
    /// The drawn signature, as a picture, named in the counter-signature by
    /// its hash the way a photograph is named in the report.
    static let signatureImage = "signature.jpg"
    /// The bundle as one file: the same files, zipped, stored. WhatsApp
    /// carries a file and not a folder.
    static let zipExtension = "snagz"

    static func hex(_ bytes: [UInt8]) -> String { bytes.map { String(format: "%02x", $0) }.joined() }
    static func sha256(_ data: Data) -> [UInt8] { Array(SHA256.hash(data: data)) }
    static func photoURL(in dir: URL, hash: [UInt8]) -> URL { dir.appendingPathComponent(photosDir).appendingPathComponent(hex(hash) + ".jpg") }

    /// Write a sealed bundle. Photographs are copied in by hash; a missing one
    /// is an error, because a report whose photograph cannot be shown is not
    /// the report that was signed.
    static func write(report: [UInt8], seal: Seal, photos: [([UInt8], URL)], to dir: URL) throws {
        try FileManager.default.createDirectory(at: dir.appendingPathComponent(photosDir), withIntermediateDirectories: true)
        try Data(report).write(to: dir.appendingPathComponent(reportFile))
        try Data(seal.signature).write(to: dir.appendingPathComponent(signatureFile))
        try Data(seal.publicKey).write(to: dir.appendingPathComponent(keyFile))
        for (hash, src) in photos {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(photosDir).appendingPathComponent(hex(hash) + ".jpg"))
            try FileManager.default.copyItem(at: src, to: dir.appendingPathComponent(photosDir).appendingPathComponent(hex(hash) + ".jpg"))
        }
    }

    /// `<id>.snagz` beside the bundle, rewritten each time it is asked for
    /// so it is never older than the bundle.
    static func zip(_ dir: URL) throws -> URL {
        let url = dir.deletingPathExtension().appendingPathExtension(zipExtension)
        try ZipFile.archive(directory: dir).write(to: url)
        return url
    }

    static func writeCounterSignature(_ bytes: [UInt8], seal: Seal, signature image: Data, to dir: URL) throws {
        try image.write(to: dir.appendingPathComponent(signatureImage))
        try Data(bytes).write(to: dir.appendingPathComponent(counterFile))
        try Data(seal.signature).write(to: dir.appendingPathComponent(counterSigFile))
    }
}
