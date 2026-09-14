// The few things a tenant can set. Off by default, every one.
import Foundation
import Observation

@MainActor
@Observable
final class Preferences {
    static let shared = Preferences()
    var lock: Bool {
        get { UserDefaults.standard.bool(forKey: "pref.lock") }
        set { UserDefaults.standard.set(newValue, forKey: "pref.lock") }
    }
    var cloud: Bool {
        get { UserDefaults.standard.bool(forKey: "pref.cloud") }
        set { UserDefaults.standard.set(newValue, forKey: "pref.cloud") }
    }
    var nudge: Bool {
        get { UserDefaults.standard.object(forKey: "pref.nudge") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "pref.nudge") }
    }
}
