// The walk on the Lock Screen: started when a walk is opened, updated as
// rooms and items arrive, ended at the seal or when the walk is left.
import ActivityKit
import Foundation
import SnagDomain

@MainActor
enum WalkActivity {
    private static var current: Activity<WalkActivityAttributes>?

    static var available: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    static func show(_ report: Report) {
        let state = WalkActivityAttributes.ContentState(rooms: report.rooms.count, items: report.itemCount, snags: report.snagCount, minutes: report.minutesWalked ?? 0)
        if let current, current.attributes.address == report.address {
            let box = Box(activity: current)
            Task { await box.activity.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }
        end()
        guard available else { return }
        current = try? Activity.request(attributes: WalkActivityAttributes(address: report.address), content: ActivityContent(state: state, staleDate: nil))
    }

    static func end() {
        guard let activity = current else { return }
        current = nil
        let box = Box(activity: activity)
        Task { await box.activity.end(nil, dismissalPolicy: .immediate) }
    }

    // ActivityKit has not marked Activity Sendable; it is used from one task at a time.
    private struct Box: @unchecked Sendable { let activity: Activity<WalkActivityAttributes> }
}
