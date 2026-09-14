// The seal you can feel. A tap at capture, a thud at the seal, a nudge at a
// refusal. UIKit's generators, which honour the system's haptics setting on
// their own; on the simulator they are silent and harmless.
import UIKit

@MainActor
enum Haptics {
    static func captured() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func sealed() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func refused() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
