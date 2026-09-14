// One local notification for a draft older than a day: seal it before the
// boxes are in. Provisional authorisation, so no permission prompt in the
// doorway — the note arrives quietly in Notification Centre. Cancelled at
// the seal, and when the draft is deleted.
import UserNotifications

enum SealNudge {
    static let after: TimeInterval = 24 * 60 * 60

    @MainActor
    static func schedule(draft id: String, address: String) async {
        guard Preferences.shared.nudge else { return }
        let centre = UNUserNotificationCenter.current()
        _ = try? await centre.requestAuthorization(options: [.alert, .provisional])
        let content = UNMutableNotificationContent()
        content.title = Strings.nudgeTitle
        content.body = "\(address) — \(Strings.nudgeBody)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: after, repeats: false)
        try? await centre.add(UNNotificationRequest(identifier: "nudge." + id, content: content, trigger: trigger))
    }

    static func cancel(draft id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["nudge." + id])
    }

    static func pending() async -> [String] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("nudge.") }
    }
}
