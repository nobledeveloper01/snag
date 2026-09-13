// Splash, then the reports list. The store is opened while the splash is up.
import SwiftUI

struct RootView: View {
    @State private var swept = false
    @State private var store = ReportStore()

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
