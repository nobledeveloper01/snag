// The one primary action per screen, pinned below the scroll — below it,
// not over it. A `safeAreaInset` lets the list run on under the buttons,
// and the accessibility audit reads a row under them as visible: at the
// larger text size it slides beneath the buttons, its measured frame stops
// growing, and the audit calls the font unsupported. A stack ends the
// scroll where the buttons begin, and a row at that edge is clipped the
// way every list clips at the bottom of the screen, which the audit knows.
import SwiftUI

struct PinnedActions<Actions: View>: ViewModifier {
    let actions: Actions
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let palette = Palette.current(scheme)
        VStack(spacing: 0) {
            content
            actions
        }
        .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}

extension View {
    func pinned<A: View>(@ViewBuilder _ actions: () -> A) -> some View {
        modifier(PinnedActions(actions: actions()))
    }
}

extension View {
    /// Room below the last row of a list that sits above pinned actions.
    /// The audit measures a row's growth at the larger sizes in place, and a
    /// text row sitting on the bottom edge of the scroll is clipped as it
    /// grows and reads as a font that does not scale. A short list keeps its
    /// last row clear of the edge; a long one scrolls anyway.
    func listRoom() -> some View { contentMargins(.bottom, 160, for: .scrollContent) }
}
