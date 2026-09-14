// The walk as data: templates that name the rooms before it starts, the
// rule that one photograph is one item, and the timeline the cover prints.
// ADR-0004. Nothing here adds a field to the report.

/// The flats Lagos actually lets. One tap names the rooms; the tenant adds
/// or removes from there.
public enum RoomTemplate: UInt8, Sendable, CaseIterable, Equatable {
    case selfContain = 0, oneBed, twoBed, threeBed, duplex

    public var word: String {
        switch self {
        case .selfContain: "self-contain"
        case .oneBed: "one bedroom"
        case .twoBed: "two bedroom"
        case .threeBed: "three bedroom"
        case .duplex: "duplex"
        }
    }

    public var rooms: [RoomName] {
        switch self {
        case .selfContain: [.livingRoom, .kitchen, .bathroom]
        case .oneBed: [.livingRoom, .bedroom, .kitchen, .bathroom, .toilet]
        case .twoBed: [.livingRoom, .bedroom, .bedroom, .kitchen, .bathroom, .toilet, .balcony]
        case .threeBed: [.livingRoom, .bedroom, .bedroom, .bedroom, .kitchen, .bathroom, .bathroom, .toilet, .corridor, .store]
        case .duplex: [.livingRoom, .kitchen, .toilet, .corridor, .bedroom, .bedroom, .bedroom, .bathroom, .bathroom, .balcony, .store]
        }
    }
}

extension Report {
    /// One photograph is one item. The same bytes in two places would be two
    /// claims about one moment, and the second is refused before it exists.
    public func contains(photoHash: Hash) -> Bool {
        rooms.contains { $0.items.contains { $0.photoHash == photoHash } }
    }

    /// First and last photograph, by the phone's clock. Nil until one exists.
    public var walked: (first: Int64, last: Int64)? {
        let times = rooms.flatMap { $0.items.map(\.takenAt) }
        guard let a = times.min(), let b = times.max() else { return nil }
        return (a, b)
    }

    /// Whole minutes from the first photograph to the last; zero for one.
    public var minutesWalked: Int? { walked.map { Int(($0.last - $0.first) / 60) } }

    /// Rooms that share a name are told apart by a number: "Bedroom 1",
    /// "Bedroom 2". A room with a name of its own keeps it.
    public var roomLabels: [String] {
        var seen: [RoomName: Int] = [:]
        for room in rooms where room.name != .other { seen[room.name, default: 0] += 1 }
        var counter: [RoomName: Int] = [:]
        return rooms.map { room in
            if room.name == .other { return room.custom ?? "" }
            guard seen[room.name, default: 0] > 1 else { return room.name.word }
            counter[room.name, default: 0] += 1
            return "\(room.name.word) \(counter[room.name]!)"
        }
    }
}
