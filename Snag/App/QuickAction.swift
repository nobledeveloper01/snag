// The Home Screen quick action arrives through UIKit's scene delegate;
// it becomes the same flag the Siri intent sets.
import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor item: UIApplicationShortcutItem) async -> Bool {
        guard item.type == "ng.snag.new" else { return false }
        await MainActor.run { Launch.shared.wantsNewReport = true }
        return true
    }
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        if options.shortcutItem?.type == "ng.snag.new" { Task { @MainActor in Launch.shared.wantsNewReport = true } }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: session.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
