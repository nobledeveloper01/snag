// The lock, when it is on: the mark, one sentence, one button.
import SwiftUI

struct LockView: View {
    let unlocked: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var failed = false

    var body: some View {
        let palette = Palette.current(scheme)
        ScrollView {
            VStack(spacing: Gap.l) {
                Mark(size: 88, color: palette.accent, ground: palette.canvas[0])
                Text(Strings.locked).font(Type.displayFont()).foregroundStyle(palette.textPrimary).multilineTextAlignment(.center)
                if failed {
                    Text(Strings.unlockFailed).font(Type.bodyFont()).foregroundStyle(palette.textSecondary).multilineTextAlignment(.center)
                        .accessibilityIdentifier("unlockFailed")
                }
            }
            .padding(Gap.xl).frame(maxWidth: .infinity)
        }
        .pinned {
            Button(Strings.unlock) { Task { if await AppLock.unlock() { unlocked() } else { failed = true } } }
                .buttonStyle(Primary(palette: palette)).padding(Gap.l)
        }
        .task { if await AppLock.unlock() { unlocked() } else { failed = true } }
    }
}
