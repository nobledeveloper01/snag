// A condition report, as data. No imports: this package depends on the Swift
// standard library and nothing else, because every signature the app makes
// is over the bytes this package produces, and those bytes must not depend
// on any platform encoder. ADR-0002.

/// How a number was made. Beside every dimension, in the app and in the PDF.
public enum Tier: UInt8, Sendable, CaseIterable, Equatable {
    case photographed = 0   // a room named and photographed; no dimensions
    case measured = 1       // ARKit: the tenant tapped the corners; ±5%
    case scanned = 2        // RoomPlan: a LiDAR walk; a floor plan exists

    public var word: String {
        switch self {
        case .photographed: "photographed"
        case .measured: "measured"
        case .scanned: "scanned"
        }
    }
}

public enum Kind: UInt8, Sendable, Equatable {
    case moveIn = 0
    case moveOut = 1
}

public enum RoomName: UInt8, Sendable, CaseIterable, Equatable {
    case livingRoom = 0, bedroom, kitchen, bathroom, toilet, balcony, corridor, store
    case other = 255

    public var word: String {
        switch self {
        case .livingRoom: "living room"
        case .bedroom: "bedroom"
        case .kitchen: "kitchen"
        case .bathroom: "bathroom"
        case .toilet: "toilet"
        case .balcony: "balcony"
        case .corridor: "corridor"
        case .store: "store"
        case .other: "other"
        }
    }
}

public enum ItemState: UInt8, Sendable, Equatable {
    case snag = 0
    case fine = 1
}

/// A length or an area in whole centimetres (or cm²), and how it was made.
/// Called Extent because Foundation has a Extent and every app file imports Foundation.
public struct Extent: Sendable, Equatable {
    public var centimetres: Int32
    public var tier: Tier
    public init(centimetres: Int32, tier: Tier) {
        self.centimetres = centimetres
        self.tier = tier
    }
}

/// A photograph is its hash. The app hashes at capture; the domain never
/// sees pixels.
public typealias Hash = [UInt8]

public struct Item: Sendable, Equatable {
    public var state: ItemState
    public var photoHash: Hash          // 32 bytes
    public var caption: String          // ≤ 280 characters
    public var takenAt: Int64           // seconds since 1970, the phone's clock
    public init(state: ItemState, photoHash: Hash, caption: String, takenAt: Int64) {
        self.state = state
        self.photoHash = photoHash
        self.caption = caption
        self.takenAt = takenAt
    }
}

public struct Room: Sendable, Equatable {
    public var name: RoomName
    public var custom: String?          // present iff name == .other
    public var width: Extent?
    public var length: Extent?
    public var area: Extent?
    public var planHash: Hash?
    public var items: [Item]
    public init(name: RoomName, custom: String? = nil, width: Extent? = nil, length: Extent? = nil,
                area: Extent? = nil, planHash: Hash? = nil, items: [Item] = []) {
        self.name = name
        self.custom = name == .other ? custom : nil
        self.width = width
        self.length = length
        self.area = area
        self.planHash = planHash
        self.items = items
    }

    /// The highest tier any number in the room carries; photographed if none.
    public var tier: Tier {
        [width, length, area].compactMap { $0?.tier }.max { $0.rawValue < $1.rawValue } ?? .photographed
    }
}

public struct Report: Sendable, Equatable {
    public static let version: UInt8 = 1
    public var kind: Kind
    public var address: String
    public var createdAt: Int64
    public var movedInReportId: Hash?   // 32 bytes, for a move-out
    public var rooms: [Room]
    public init(kind: Kind, address: String, createdAt: Int64, movedInReportId: Hash? = nil, rooms: [Room] = []) {
        self.kind = kind
        self.address = address
        self.createdAt = createdAt
        self.movedInReportId = movedInReportId
        self.rooms = rooms
    }

    public var itemCount: Int { rooms.reduce(0) { $0 + $1.items.count } }
    public var snagCount: Int { rooms.reduce(0) { $0 + $1.items.filter { $0.state == .snag }.count } }
    /// The highest tier any number in the report carries.
    public var tier: Tier { rooms.map(\.tier).max { $0.rawValue < $1.rawValue } ?? .photographed }
}

/// The other party's signature, appended after sealing as its own layer.
public struct CounterSignature: Sendable, Equatable {
    public static let version: UInt8 = 1
    public var reportId: Hash           // 32 bytes
    public var name: String
    public var phone: String
    public var signatureHash: Hash      // the drawn signature, as a photograph
    public var signedAt: Int64
    public init(reportId: Hash, name: String, phone: String, signatureHash: Hash, signedAt: Int64) {
        self.reportId = reportId
        self.name = name
        self.phone = phone
        self.signatureHash = signatureHash
        self.signedAt = signedAt
    }
}
