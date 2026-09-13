// The canonical encoding — the one byte-exact serialisation of a report that
// every signature is over. Version 1. Hand-written, length-prefixed,
// field-ordered, big-endian, no floats, no maps, no dependency on any
// encoder. A person can read this file and re-implement it in another
// language, which is the point: a court's expert can verify a bundle without
// this app. docs/BUNDLE-FORMAT.md is the spec; the fixture in the tests is
// the promise that it never changes.
//
//   u8  version = 1
//   u8  kind
//   str address            u16 length + UTF-8
//   i64 createdAt
//   opt movedInReportId    u8 flag, then 32 bytes
//   u16 roomCount
//     room: u8 name, opt str custom (iff name == 255), opt dim width, opt dim length,
//           opt dim area, opt hash32 planHash, u16 itemCount, items…
//     dim:  u8 flag, then i32 centimetres + u8 tier
//     item: u8 state, 32 bytes photoHash, str caption, i64 takenAt

public enum CanonicalError: Error, Equatable {
    case truncated
    case badVersion(UInt8)
    case badValue(String)
    case captionTooLong
    case hashNotThirtyTwoBytes
}

public enum Canonical {
    public static let maxCaption = 280

    // MARK: encode

    public static func bytes(of r: Report) throws -> [UInt8] {
        var out: [UInt8] = [Report.version, r.kind.rawValue]
        try putString(&out, r.address)
        putI64(&out, r.createdAt)
        try putOptHash(&out, r.movedInReportId)
        putU16(&out, r.rooms.count)
        for room in r.rooms {
            out.append(room.name.rawValue)
            if room.name == .other { try putString(&out, room.custom ?? "") }
            putOptDim(&out, room.width); putOptDim(&out, room.length); putOptDim(&out, room.area)
            try putOptHash(&out, room.planHash)
            putU16(&out, room.items.count)
            for item in room.items {
                out.append(item.state.rawValue)
                try putHash(&out, item.photoHash)
                guard item.caption.count <= maxCaption else { throw CanonicalError.captionTooLong }
                try putString(&out, item.caption)
                putI64(&out, item.takenAt)
            }
        }
        return out
    }

    public static func bytes(of c: CounterSignature) throws -> [UInt8] {
        var out: [UInt8] = [CounterSignature.version]
        try putHash(&out, c.reportId)
        try putString(&out, c.name)
        try putString(&out, c.phone)
        try putHash(&out, c.signatureHash)
        putI64(&out, c.signedAt)
        return out
    }

    // MARK: decode

    public static func report(from bytes: [UInt8]) throws -> Report {
        var i = 0
        let v = try u8(bytes, &i)
        guard v == Report.version else { throw CanonicalError.badVersion(v) }
        guard let kind = Kind(rawValue: try u8(bytes, &i)) else { throw CanonicalError.badValue("kind") }
        let address = try string(bytes, &i)
        let createdAt = try i64(bytes, &i)
        let movedIn = try optHash(bytes, &i)
        let roomCount = try u16(bytes, &i)
        var rooms: [Room] = []
        for _ in 0..<roomCount {
            guard let name = RoomName(rawValue: try u8(bytes, &i)) else { throw CanonicalError.badValue("room name") }
            let custom = name == .other ? try string(bytes, &i) : nil
            let width = try optDim(bytes, &i), length = try optDim(bytes, &i), area = try optDim(bytes, &i)
            let plan = try optHash(bytes, &i)
            let itemCount = try u16(bytes, &i)
            var items: [Item] = []
            for _ in 0..<itemCount {
                guard let state = ItemState(rawValue: try u8(bytes, &i)) else { throw CanonicalError.badValue("item state") }
                let photo = try hash(bytes, &i)
                let caption = try string(bytes, &i)
                let takenAt = try i64(bytes, &i)
                items.append(Item(state: state, photoHash: photo, caption: caption, takenAt: takenAt))
            }
            rooms.append(Room(name: name, custom: custom, width: width, length: length, area: area, planHash: plan, items: items))
        }
        guard i == bytes.count else { throw CanonicalError.badValue("trailing bytes") }
        return Report(kind: kind, address: address, createdAt: createdAt, movedInReportId: movedIn, rooms: rooms)
    }

    public static func counterSignature(from bytes: [UInt8]) throws -> CounterSignature {
        var i = 0
        let v = try u8(bytes, &i)
        guard v == CounterSignature.version else { throw CanonicalError.badVersion(v) }
        let id = try hash(bytes, &i)
        let name = try string(bytes, &i), phone = try string(bytes, &i)
        let sig = try hash(bytes, &i)
        let at = try i64(bytes, &i)
        guard i == bytes.count else { throw CanonicalError.badValue("trailing bytes") }
        return CounterSignature(reportId: id, name: name, phone: phone, signatureHash: sig, signedAt: at)
    }

    // MARK: primitives

    private static func putU16(_ out: inout [UInt8], _ n: Int) {
        out.append(UInt8(n >> 8 & 0xFF)); out.append(UInt8(n & 0xFF))
    }
    private static func putI32(_ out: inout [UInt8], _ n: Int32) {
        let u = UInt32(bitPattern: n)
        for s in stride(from: 24, through: 0, by: -8) { out.append(UInt8(u >> UInt32(s) & 0xFF)) }
    }
    private static func putI64(_ out: inout [UInt8], _ n: Int64) {
        let u = UInt64(bitPattern: n)
        for s in stride(from: 56, through: 0, by: -8) { out.append(UInt8(u >> UInt64(s) & 0xFF)) }
    }
    private static func putString(_ out: inout [UInt8], _ s: String) throws {
        let utf8 = Array(s.utf8)
        guard utf8.count <= 0xFFFF else { throw CanonicalError.badValue("string too long") }
        putU16(&out, utf8.count); out += utf8
    }
    private static func putHash(_ out: inout [UInt8], _ h: Hash) throws {
        guard h.count == 32 else { throw CanonicalError.hashNotThirtyTwoBytes }
        out += h
    }
    private static func putOptHash(_ out: inout [UInt8], _ h: Hash?) throws {
        if let h { out.append(1); try putHash(&out, h) } else { out.append(0) }
    }
    private static func putOptDim(_ out: inout [UInt8], _ d: Extent?) {
        if let d { out.append(1); putI32(&out, d.centimetres); out.append(d.tier.rawValue) } else { out.append(0) }
    }

    private static func u8(_ b: [UInt8], _ i: inout Int) throws -> UInt8 {
        guard i < b.count else { throw CanonicalError.truncated }
        defer { i += 1 }; return b[i]
    }
    private static func u16(_ b: [UInt8], _ i: inout Int) throws -> Int {
        Int(try u8(b, &i)) << 8 | Int(try u8(b, &i))
    }
    private static func i32(_ b: [UInt8], _ i: inout Int) throws -> Int32 {
        var u: UInt32 = 0
        for _ in 0..<4 { u = u << 8 | UInt32(try u8(b, &i)) }
        return Int32(bitPattern: u)
    }
    private static func i64(_ b: [UInt8], _ i: inout Int) throws -> Int64 {
        var u: UInt64 = 0
        for _ in 0..<8 { u = u << 8 | UInt64(try u8(b, &i)) }
        return Int64(bitPattern: u)
    }
    private static func string(_ b: [UInt8], _ i: inout Int) throws -> String {
        let n = try u16(b, &i)
        guard i + n <= b.count else { throw CanonicalError.truncated }
        defer { i += n }
        return String(decoding: b[i..<i + n], as: UTF8.self)
    }
    private static func hash(_ b: [UInt8], _ i: inout Int) throws -> Hash {
        guard i + 32 <= b.count else { throw CanonicalError.truncated }
        defer { i += 32 }
        return Array(b[i..<i + 32])
    }
    private static func optHash(_ b: [UInt8], _ i: inout Int) throws -> Hash? {
        try u8(b, &i) == 1 ? try hash(b, &i) : nil
    }
    private static func optDim(_ b: [UInt8], _ i: inout Int) throws -> Extent? {
        guard try u8(b, &i) == 1 else { return nil }
        let cm = try i32(b, &i)
        guard let tier = Tier(rawValue: try u8(b, &i)) else { throw CanonicalError.badValue("tier") }
        return Extent(centimetres: cm, tier: tier)
    }
}
