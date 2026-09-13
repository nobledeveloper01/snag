// The list of reports, and the empty state that is most tenants' first
// screen: one sentence, one button.
import SwiftUI
import SnagDomain

struct ReportsListView: View {
    @Bindable var store: ReportStore
    @Environment(\.colorScheme) private var scheme
    @State private var creating = false

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            ZStack {
                LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                if store.drafts.isEmpty {
                    // In a ScrollView, so the largest text sizes scroll rather
                    // than clip — the audit found it on the first run.
                    ScrollView {
                        VStack(spacing: Gap.l) {
                            Mark(size: 88, color: palette.accent, ground: palette.canvas[0])
                            Text(Strings.emptyTitle).font(Type.displayFont()).foregroundStyle(palette.textPrimary).multilineTextAlignment(.center)
                            Text(Strings.emptyHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary).multilineTextAlignment(.center)
                        }
                        .padding(Gap.xl)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    List(store.drafts) { draft in
                        NavigationLink(value: draft.id) {
                            VStack(alignment: .leading, spacing: Gap.xs) {
                                Text(draft.report.address).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                                Text("\(draft.report.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(draft.report.rooms.count) \(Strings.room.lowercased())s · \(draft.report.snagCount) \(Strings.snags)")
                                    .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                            .frame(minHeight: Target.standard)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(Strings.newReport) { creating = true }
                    .buttonStyle(Primary(palette: palette))
                    .padding(Gap.l)
            }
            .navigationTitle(Strings.reports)
            .navigationDestination(for: Int.self) { id in
                if let draft = store.drafts.first(where: { $0.id == id }) { WalkView(store: store, draftId: draft.id) }
            }
            .sheet(isPresented: $creating) { NewReportSheet(store: store) }
        }
        .tint(palette.accent)
    }
}

/// The one primary action per screen, pinned below the scroll: 64 pt, the
/// accent, full width.
struct Primary: ButtonStyle {
    let palette: Palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.headlineFont())
            .foregroundStyle(palette.onAccent)
            .frame(maxWidth: .infinity, minHeight: Target.primary)
            .background(palette.accent, in: RoundedRectangle(cornerRadius: Radius.card))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
