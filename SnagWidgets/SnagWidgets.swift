// The walk on the Lock Screen and in the Dynamic Island: one line of
// numbers and the address, updated as the tenant moves through the flat.
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SnagWidgets: WidgetBundle {
    var body: some Widget { WalkLiveActivity() }
}

struct WalkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.address).font(.headline).lineLimit(1)
                Text(line(context.state)).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.06, green: 0.063, blue: 0.07))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text(context.attributes.address).font(.caption).lineLimit(1) }
                DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.minutes) min").font(.caption) }
                DynamicIslandExpandedRegion(.bottom) { Text(line(context.state)).font(.caption2) }
            } compactLeading: {
                Image(systemName: "camera.fill")
            } compactTrailing: {
                Text("\(context.state.snags)")
            } minimal: {
                Image(systemName: "camera.fill")
            }
        }
    }

    private func line(_ s: WalkActivityAttributes.ContentState) -> String {
        "\(s.rooms) rooms · \(s.items) items · \(s.snags) snags · \(s.minutes) min"
    }
}
