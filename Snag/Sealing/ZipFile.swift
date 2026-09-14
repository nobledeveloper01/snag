// A bundle as one file, because WhatsApp does not carry a folder. A plain
// zip: entries stored, not deflated — the photographs are JPEGs and do not
// shrink, and a stored entry is the bytes themselves, which is what a
// verifier wants to hash. Reading accepts stored and deflated entries, so
// a bundle re-zipped by somebody's desktop still opens. Written here
// rather than taken from a library because the format is forty lines and
// the dependency would be the only one in the app.
import Compression
import Foundation

enum ZipFile {
    struct Entry { let name: String; let data: Data }
    enum Failure: Error { case notAZip, badEntry, unsupportedMethod(UInt16), crc }

    // MARK: write

    static func archive(_ entries: [Entry]) -> Data {
        var out = Data()
        var central = Data()
        for e in entries {
            let name = Data(e.name.utf8)
            let crc = crc32(e.data)
            let offset = UInt32(out.count)
            out.append(le32(0x0403_4b50)); out.append(le16(20)); out.append(le16(0x0800)); out.append(le16(0))
            out.append(le16(0)); out.append(le16(0x21))                       // time 00:00, date 1980-01-01
            out.append(le32(crc)); out.append(le32(UInt32(e.data.count))); out.append(le32(UInt32(e.data.count)))
            out.append(le16(UInt16(name.count))); out.append(le16(0))
            out.append(name); out.append(e.data)
            central.append(le32(0x0201_4b50)); central.append(le16(20)); central.append(le16(20)); central.append(le16(0x0800)); central.append(le16(0))
            central.append(le16(0)); central.append(le16(0x21))
            central.append(le32(crc)); central.append(le32(UInt32(e.data.count))); central.append(le32(UInt32(e.data.count)))
            central.append(le16(UInt16(name.count))); central.append(le16(0)); central.append(le16(0))
            central.append(le16(0)); central.append(le16(0)); central.append(le32(0)); central.append(le32(offset))
            central.append(name)
        }
        let cdOffset = UInt32(out.count)
        out.append(central)
        out.append(le32(0x0605_4b50)); out.append(le16(0)); out.append(le16(0))
        out.append(le16(UInt16(entries.count))); out.append(le16(UInt16(entries.count)))
        out.append(le32(UInt32(central.count))); out.append(le32(cdOffset)); out.append(le16(0))
        return out
    }

    /// Every regular file under `dir`, named relative to it, sorted, so the
    /// same bundle zips to the same bytes.
    static func archive(directory dir: URL) throws -> Data {
        let fm = FileManager.default
        var entries: [Entry] = []
        guard let walker = fm.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey]) else { return archive([]) }
        for case let url as URL in walker where (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
            let rel = url.path.replacingOccurrences(of: dir.path + "/", with: "")
            entries.append(Entry(name: rel, data: try Data(contentsOf: url)))
        }
        return archive(entries.sorted { $0.name < $1.name })
    }

    // MARK: read

    static func entries(_ data: Data) throws -> [Entry] {
        let bytes = [UInt8](data)
        // The end-of-central-directory record is within the last 64 KB.
        var eocd = -1
        var i = bytes.count - 22
        while i >= max(0, bytes.count - 65_557) {
            if u32(bytes, i) == 0x0605_4b50 { eocd = i; break }
            i -= 1
        }
        guard eocd >= 0 else { throw Failure.notAZip }
        let count = Int(u16(bytes, eocd + 10))
        var p = Int(u32(bytes, eocd + 16))
        var out: [Entry] = []
        for _ in 0..<count {
            guard p + 46 <= bytes.count, u32(bytes, p) == 0x0201_4b50 else { throw Failure.badEntry }
            let method = u16(bytes, p + 10)
            let crc = u32(bytes, p + 16)
            let csize = Int(u32(bytes, p + 20)), usize = Int(u32(bytes, p + 24))
            let nlen = Int(u16(bytes, p + 28)), xlen = Int(u16(bytes, p + 30)), clen = Int(u16(bytes, p + 32))
            let local = Int(u32(bytes, p + 42))
            guard p + 46 + nlen <= bytes.count, let name = String(bytes: bytes[(p + 46)..<(p + 46 + nlen)], encoding: .utf8) else { throw Failure.badEntry }
            guard local + 30 <= bytes.count, u32(bytes, local) == 0x0403_4b50 else { throw Failure.badEntry }
            let start = local + 30 + Int(u16(bytes, local + 26)) + Int(u16(bytes, local + 28))
            guard start + csize <= bytes.count else { throw Failure.badEntry }
            let raw = Data(bytes[start..<(start + csize)])
            let data: Data
            switch method {
            case 0: data = raw
            case 8: data = try inflate(raw, size: usize)
            default: throw Failure.unsupportedMethod(method)
            }
            guard crc32(data) == crc else { throw Failure.crc }
            if !name.hasSuffix("/") { out.append(Entry(name: name, data: data)) }
            p += 46 + nlen + xlen + clen
        }
        return out
    }

    /// Unpack into `dir`, refusing names that would escape it.
    static func extract(_ data: Data, to dir: URL) throws {
        for e in try entries(data) {
            let parts = e.name.split(separator: "/")
            guard !parts.contains(".."), !e.name.hasPrefix("/") else { throw Failure.badEntry }
            let target = parts.reduce(dir) { $0.appendingPathComponent(String($1)) }
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try e.data.write(to: target)
        }
    }

    private static func inflate(_ raw: Data, size: Int) throws -> Data {
        guard size > 0 else { return Data() }
        var out = Data(count: size)
        let n = out.withUnsafeMutableBytes { dst in
            raw.withUnsafeBytes { src in
                compression_decode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, size,
                                          src.bindMemory(to: UInt8.self).baseAddress!, raw.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard n == size else { throw Failure.badEntry }
        return out
    }

    // MARK: bytes

    private static func le16(_ v: UInt16) -> Data { Data([UInt8(v & 0xff), UInt8(v >> 8)]) }
    private static func le32(_ v: UInt32) -> Data { Data([UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8(v >> 24)]) }
    private static func u16(_ b: [UInt8], _ i: Int) -> UInt16 { UInt16(b[i]) | UInt16(b[i + 1]) << 8 }
    private static func u32(_ b: [UInt8], _ i: Int) -> UInt32 { UInt32(b[i]) | UInt32(b[i + 1]) << 8 | UInt32(b[i + 2]) << 16 | UInt32(b[i + 3]) << 24 }

    private static let table: [UInt32] = (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }
    static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in data { c = table[Int((c ^ UInt32(b)) & 0xff)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }
}
