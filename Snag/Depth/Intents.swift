// "Start a Snag report" from Siri, Shortcuts, Spotlight, or the Home
// Screen's quick action. The intent opens the app on the new-report sheet
// and does nothing else; the phone runs it, nobody's server does.
import AppIntents
import SwiftUI

@MainActor
@Observable
final class Launch {
    static let shared = Launch()
    var wantsNewReport = false
}

struct StartReportIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Snag report"
    static let description = IntentDescription("Opens Snag on a new condition report.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Launch.shared.wantsNewReport = true
        return .result()
    }
}

struct SnagShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartReportIntent(), phrases: ["Start a \(.applicationName) report", "New \(.applicationName) report"],
                    shortTitle: "Start a report", systemImageName: "camera.fill")
    }
}
