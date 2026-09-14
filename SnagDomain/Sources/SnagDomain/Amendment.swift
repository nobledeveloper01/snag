// A report measured or scanned after it was sealed. The original seal is
// never touched — its bytes and its signature stand — and the amendment is
// a second signed layer beside it, the way the counter-signature is: the
// original's id, then the whole amended report, signed with the same key.
// A verifier that knows only version 1 still verifies the original; one
// that knows this layer verifies both and shows the amended numbers.
// Nothing in the report's own encoding changes. ADR-0005.

public struct Amendment: Sendable, Equatable {
    public static let version: UInt8 = 1
    public var originalId: Hash          // SHA-256 of the sealed report.bin
    public var amendedAt: Int64          // seconds since 1970, the phone's clock
    public var report: Report            // the whole report, with the new numbers
    public init(originalId: Hash, amendedAt: Int64, report: Report) {
        self.originalId = originalId
        self.amendedAt = amendedAt
        self.report = report
    }
}

extension Canonical {
    public static func bytes(of a: Amendment) throws -> [UInt8] {
        guard a.originalId.count == 32 else { throw CanonicalError.hashNotThirtyTwoBytes }
        var out: [UInt8] = [Amendment.version] + a.originalId
        let u = UInt64(bitPattern: a.amendedAt)
        for s in stride(from: 56, through: 0, by: -8) { out.append(UInt8(u >> UInt64(s) & 0xFF)) }
        return out + (try bytes(of: a.report))
    }

    public static func amendment(from bytes: [UInt8]) throws -> Amendment {
        guard let v = bytes.first else { throw CanonicalError.truncated }
        guard v == Amendment.version else { throw CanonicalError.badVersion(v) }
        guard bytes.count >= 41 else { throw CanonicalError.truncated }
        let id = Array(bytes[1..<33])
        var u: UInt64 = 0
        for b in bytes[33..<41] { u = u << 8 | UInt64(b) }
        return Amendment(originalId: id, amendedAt: Int64(bitPattern: u), report: try report(from: Array(bytes[41...])))
    }
}

extension Report {
    /// What an amendment may change: the numbers and the plan of each room.
    /// Rooms, items, photographs, captions, the address and the date stay
    /// what they were — an amendment measures, it does not re-walk.
    public func amendsOnlyNumbers(of original: Report) -> Bool {
        guard kind == original.kind, address == original.address, createdAt == original.createdAt,
              movedInReportId == original.movedInReportId, rooms.count == original.rooms.count else { return false }
        for (a, b) in zip(rooms, original.rooms) {
            guard a.name == b.name, a.custom == b.custom, a.items == b.items else { return false }
            guard a.tier.rawValue >= b.tier.rawValue else { return false }
        }
        return true
    }
}
