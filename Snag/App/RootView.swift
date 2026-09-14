// Splash, then the reports list. The store is opened while the splash is up.
import SwiftUI

struct RootView: View {
    @State private var swept = false
    @State private var unlocked = false
    // -freshStore empties the store before the UI tests, so a run never
    // sees the last run's reports.
    @State private var store: ReportStore = {
        if CommandLine.arguments.contains("-freshStore") {
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Snag")
            try? FileManager.default.removeItem(at: root)
            UserDefaults.standard.removeObject(forKey: "resume.draft")
            UserDefaults.standard.removeObject(forKey: "pref.lock")
        }

        return ReportStore()
    }()

    /// The lock, as set — or forced by `-lock` for the UI test that looks at
    /// the locked screen, without writing the setting, so no later launch
    /// (the unit-test host least of all) finds itself behind a passcode sheet.
    private static var locks: Bool {
        if CommandLine.arguments.contains("-lock") { return true }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return false }
        return Preferences.shared.lock
    }

    var body: some View {
        ZStack {
            if swept, Self.locks, !unlocked {
                LockView { unlocked = true }.transition(.opacity)
            } else if swept {
                ReportsListView(store: store).transition(.opacity)
            } else {
                SplashView { swept = true }
            }
        }
        .animation(.easeOut(duration: 0.25), value: swept)
    }
}
