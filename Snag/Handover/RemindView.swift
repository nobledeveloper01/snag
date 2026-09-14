// The day the tenancy ends, as a date; one event in the tenant's calendar.
import SwiftUI

struct RemindView: View {
    let address: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var day = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var outcome: Reminder.Outcome?
    @State private var busy = false

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Gap.m) {
                    Text(Strings.remindHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                    Text(Strings.tenancyEnds).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    // Compact, not graphical: the calendar grid is the system's
                    // and the audit reads its day numbers as text it cannot reach.
                    DatePicker(Strings.tenancyEnds, selection: $day, in: Date.now..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .font(Type.bodyFont())
                        .frame(minHeight: Target.standard)
                        .accessibilityIdentifier("day")
                    if let outcome {
                        Text(outcome == .added ? Strings.reminderAdded : outcome == .denied ? Strings.reminderDenied : Strings.sealFailed)
                            .font(Type.bodyFont()).foregroundStyle(outcome == .added ? palette.fine : palette.snag)
                            .frame(minHeight: Target.standard)
                            .accessibilityIdentifier("outcome")
                    }
                }
                .padding(Gap.l)
            }
            .pinned {
                VStack(spacing: Gap.s) {
                    if outcome == .added {
                        Button(Strings.done) { dismiss() }.buttonStyle(Primary(palette: palette))
                    } else {
                        Button(Strings.addReminder) {
                            busy = true
                            Task {
                                outcome = await Reminder.add(title: "\(Strings.appName): \(Strings.moveOut) — \(address)", notes: Strings.remind, on: day)
                                busy = false
                            }
                        }
                        .buttonStyle(Primary(palette: palette)).disabled(busy)
                        Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                    }
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.remind)
        }
        .tint(palette.accent)
    }
}
