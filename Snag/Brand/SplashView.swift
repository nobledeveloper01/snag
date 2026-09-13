// The portfolio's splash: the mark, a warm bloom, the wordmark, about 1.2 s.
// Driven by a timer, never by an animation, so Reduce Motion gets the
// finished frame for the same duration rather than nothing.
import SwiftUI
import UIKit

struct SplashView: View {
    let onSwept: @MainActor () -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var grown = false
    @State private var bloomed = false

    static let duration: TimeInterval = 1.2
    private var reduceMotion: Bool { systemReduceMotion || CommandLine.arguments.contains("-reduceMotion") }

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            Circle().fill(palette.accent.opacity(bloomed ? 0.16 : 0)).frame(width: 260, height: 260).blur(radius: 40)
            VStack(spacing: Gap.m) {
                Mark(size: 120, color: palette.accent, ground: palette.canvas[0])
                    .scaleEffect(grown ? 1 : 0.85).opacity(grown ? 1 : 0)
                Text(Strings.appName).font(Type.displayFont()).foregroundStyle(palette.textPrimary).opacity(grown ? 1 : 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.appName)
        .onAppear {
            if reduceMotion { grown = true; bloomed = true } else {
                withAnimation(.easeOut(duration: 0.45)) { grown = true }
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) { bloomed = true }
            }
            UIAccessibility.post(notification: .announcement, argument: Strings.appName)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Self.duration))
                onSwept()
            }
        }
    }
}
