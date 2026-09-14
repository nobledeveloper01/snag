// Splash, then the reports list. The store is opened while the splash is up.
import SwiftUI

struct RootView: View {
    @State private var swept = false
    // -freshStore empties the store before the UI tests, so a run never
    // sees the last run's reports.
    @State private var store: ReportStore = {
        if CommandLine.arguments.contains("-freshStore") {
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Snag")
            try? FileManager.default.removeItem(at: root)
            UserDefaults.standard.removeObject(forKey: "resume.draft")
        }
        return ReportStore()
    }()

    var body: some View {
        ZStack {
            if swept {
                ReportsListView(store: store).transition(.opacity)
            } else {
                SplashView { swept = true }
            }
        }
        .animation(.easeOut(duration: 0.25), value: swept)
    }
}
