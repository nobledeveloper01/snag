// Face ID or the passcode, before the reports are shown. Off by default: a
// report is not a secret, but an agent's phone with fifty of them may want
// it. The phone's own authentication; Snag stores nothing about it.
import LocalAuthentication

enum AppLock {
    static var canLock: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static func unlock() async -> Bool {
        let ctx = LAContext()
        ctx.localizedReason = Strings.unlockReason
        return (try? await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: Strings.unlockReason)) ?? false
    }
}
