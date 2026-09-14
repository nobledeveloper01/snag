// A note in the tenant's own calendar for the day the tenancy ends. The
// calendar is theirs; Snag writes one event and reads nothing. EventKit's
// write-only access is the least the phone offers, and it is all this asks.
import EventKit
import Foundation

enum Reminder {
    enum Outcome: Equatable { case added, denied, failed }

    static func add(title: String, notes: String, on day: Date) async -> Outcome {
        let store = EKEventStore()
        let allowed = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        guard allowed else { return .denied }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.isAllDay = true
        event.startDate = day
        event.endDate = day
        event.calendar = store.defaultCalendarForNewEvents
        do { try store.save(event, span: .thisEvent); return .added } catch { return .failed }
    }
}
