// The list of reports, and the empty state that is most tenants' first
// screen: one sentence, one button. Drafts above, sealed below.
import SwiftUI
import SnagDomain

struct ReportsListView: View {
    @Bindable var store: ReportStore
    @Environment(\.colorScheme) private var scheme
    @State private var creating = false
    @State private var checking = false
    @State private var path: [Route] = []
    @State private var opened: URL?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                if store.drafts.isEmpty && store.sealed.isEmpty {
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
                    List {
                        if !store.drafts.isEmpty {
                            Section {
                                ForEach(store.drafts) { draft in
                                    NavigationLink(value: Route.draft(draft.id)) { row(draft.report, palette) }
                                }
                            } header: {
                                Text(Strings.inProgress).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                        }
                        if !store.sealed.isEmpty {
                            Section {
                                ForEach(store.sealed) { s in
                                    NavigationLink(value: Route.sealed(s.id)) { row(s.report, palette) }
                                }
                            } header: {
                                Text(Strings.sealed).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                .listRoom()
            .listRoom()
                }
            }
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.newReport) { creating = true }
                        .buttonStyle(Primary(palette: palette))
                    if !store.sealed.isEmpty {
                        Button(Strings.checkPaper) { checking = true }.buttonStyle(Secondary(palette: palette))
                    }
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.reports)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .draft(let id): WalkView(store: store, draftId: id, path: $path)
                case .room(let id, let i): RoomView(store: store, draftId: id, roomIndex: i)
                case .sealed(let id):
                    if let s = store.sealed.first(where: { $0.id == id }) { SealedView(store: store, sealed: s) }
                }
            }
            .sheet(isPresented: $creating) { NewReportSheet(store: store) }
            .sheet(isPresented: $checking) { CheckPaperView(store: store) }
            .sheet(item: $opened) { url in VerifyView(url: url) }
        }
        .tint(palette.accent)
        .onOpenURL { url in opened = url }
        .onAppear {
            // A draft survives a kill: the walk resumes in the room it was in.
            if path.isEmpty, let r = store.resume, let d = store.drafts.first(where: { $0.id == r.draft }), r.room < d.report.rooms.count {
                path = [.draft(r.draft), .room(r.draft, r.room)]
            }
            // -openLatest: the UI test's stand-in for a bundle arriving through
            // the share sheet, which the simulator cannot deliver.
            if CommandLine.arguments.contains("-openLatest"), let s = store.sealed.last { opened = s.url }
            if CommandLine.arguments.contains("-scanLatest") { checking = true }
        }
    }

    private func row(_ report: Report, _ palette: Palette) -> some View {
        VStack(alignment: .leading, spacing: Gap.xs) {
            Text(report.address).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
            Text("\(report.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(report.rooms.count) \(Strings.room.lowercased())s · \(report.snagCount) \(Strings.snags)")
                .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
        }
        .frame(minHeight: Target.standard)
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

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

/// The quieter second action: a full-width row, not a toolbar item, because
/// toolbar items stop scaling at the largest text sizes.
struct Secondary: ButtonStyle {
    let palette: Palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.bodyFont())
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Target.standard)
            .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
