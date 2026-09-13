// Move-out against move-in: what changed, in the tenant's words.
public enum Change: Sendable, Equatable {
    case same(room: Int, item: Int)
    case changed(room: Int, item: Int, from: Item, to: Item)
    case added(room: Int, item: Item)
    case missing(room: Int, item: Item)
}

public enum Compare {
    /// Pairs items by room order and item index; a move-out item that says
    /// "same" carries the move-in photo hash and an empty caption.
    public static func diff(movedIn: Report, movedOut: Report) -> [Change] {
        var out: [Change] = []
        for (r, room) in movedIn.rooms.enumerated() {
            let after = r < movedOut.rooms.count ? movedOut.rooms[r].items : []
            for (i, item) in room.items.enumerated() {
                if i < after.count {
                    let now = after[i]
                    if now.photoHash == item.photoHash && now.state == item.state {
                        out.append(.same(room: r, item: i))
                    } else {
                        out.append(.changed(room: r, item: i, from: item, to: now))
                    }
                } else {
                    out.append(.missing(room: r, item: item))
                }
            }
            for i in room.items.count..<max(after.count, room.items.count) {
                out.append(.added(room: r, item: after[i]))
            }
        }
        return out
    }
}
