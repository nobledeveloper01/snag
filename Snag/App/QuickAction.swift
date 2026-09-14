// The Home Screen quick action becomes the same flag the Siri intent sets.
// Through the app delegate, not a scene delegate of our own: replacing
// SwiftUI's scene delegate class made the app hang as a test host one run
// in three, and UIKit forwards the action here when the scene delegate
// does not take it.
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem, item.type == "ng.snag.new" {
            Task { @MainActor in Launch.shared.wantsNewReport = true }
        }
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard shortcutItem.type == "ng.snag.new" else { return completionHandler(false) }
        Task { @MainActor in Launch.shared.wantsNewReport = true }
        completionHandler(true)
    }
}
