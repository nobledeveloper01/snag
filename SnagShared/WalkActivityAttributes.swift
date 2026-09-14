// What the Lock Screen shows while a walk is on: the address, the rooms,
// the items, the snags, the minutes. Shared by the app, which starts and
// updates it, and the widget extension, which draws it. Nothing here
// leaves the phone; a Live Activity is the phone's own screen.
import ActivityKit

struct WalkActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var rooms: Int
        var items: Int
        var snags: Int
        var minutes: Int
    }
    var address: String
}
