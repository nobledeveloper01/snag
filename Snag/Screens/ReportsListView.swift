// The list of reports, and the empty state that is most tenants' first
// screen: one sentence, one button. Drafts above, sealed below.
import SwiftUI
import SnagDomain

struct ReportsListView: View {
    @Bindable var store: ReportStore
    @Environment(\.colorScheme) private var scheme
    @State private var creating = false
    @State private var checking = false
    @State private var settings = false
    @State private var query = ""
    @State private var launch = Launch.shared
    @State private var path: [Route] = []
    @State private var opened: URL?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                if store.drafts.isEmpty && store.sealed.isEmpty && store.broken.isEmpty {
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
                    let drafts = store.drafts.filter { matches($0.report) }.sorted { $0.report.createdAt > $1.report.createdAt }
                    let sealed = store.sealed.filter { matches($0.report) }.sorted { $0.report.createdAt > $1.report.createdAt }
                    List {
                        // An agent with five flats finds one by its address.
                        if store.drafts.count + store.sealed.count > 2 {
                            Section {
                                TextField(Strings.search, text: $query).font(Type.bodyFont())
                                    .textInputAutocapitalization(.words).autocorrectionDisabled()
                                    .frame(minHeight: Target.standard)
                                    .accessibilityLabel(Strings.search).accessibilityIdentifier("search")
                            }
                        }
                        if !drafts.isEmpty {
                            Section {
                                ForEach(drafts) { draft in
                                    NavigationLink(value: Route.draft(draft.id)) { row(draft.report, palette) }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { store.delete(draft: draft) } label: { Label(Strings.delete, systemImage: "trash") }
                                        }
                                }
                            } header: {
                                Text(Strings.inProgress).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                        }
                        if !sealed.isEmpty {
                            Section {
                                ForEach(sealed) { s in
                                    NavigationLink(value: Route.sealed(s.id)) { row(s.report, palette) }
                                }
                            } header: {
                                Text(Strings.sealed).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                        }
                        // A bundle that no longer reads is listed as what it is.
                        if !store.broken.isEmpty {
                            Section {
                                ForEach(store.broken, id: \.self) { url in
                                    Button { opened = url } label: {
                                        VStack(alignment: .leading, spacing: Gap.xs) {
                                            Text(Strings.altered).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                                            Text(String(url.deletingPathExtension().lastPathComponent.prefix(16)) + "…").font(Type.secondaryFont().monospaced()).foregroundStyle(palette.textSecondary)
                                        }
                                        .frame(minHeight: Target.standard)
                                    }
                                }
                            } header: {
                                Text(Strings.cannotBeRead).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listRoom()
                }
            }
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.newReport) { creating = true }
                        .buttonStyle(Primary(palette: palette))
                    HStack(spacing: Gap.s) {
                        if !store.sealed.isEmpty || !store.broken.isEmpty {
                            Button(Strings.checkPaper) { checking = true }.buttonStyle(Secondary(palette: palette))
                        }
                        Button(Strings.settings) { settings = true }.buttonStyle(Secondary(palette: palette))
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
            // "Walk the flat" walks: the sheet closes and the walk opens.
            .sheet(isPresented: $creating) { NewReportSheet(store: store) { draft in path = [.draft(draft.id)] } }
            .sheet(isPresented: $checking) { CheckPaperView(store: store) }
            .sheet(isPresented: $settings) { SettingsView(store: store) }
            .sheet(item: $opened) { url in VerifyView(url: url, store: store) }
        }
        .tint(palette.accent)
        .onOpenURL { url in
            // snag://new from the quick action; anything else is a bundle.
            if url.scheme == "snag" { creating = true } else { opened = url }
        }
        .onChange(of: launch.wantsNewReport) { _, wants in if wants { creating = true; launch.wantsNewReport = false } }
        .onAppear {
            // A draft survives a kill: the walk resumes in the room it was in.
            if path.isEmpty, let r = store.resume, let d = store.drafts.first(where: { $0.id == r.draft }), r.room < d.report.rooms.count {
                path = [.draft(r.draft), .room(r.draft, r.room)]
            }
            // -openLatest: the UI test's stand-in for a bundle arriving through
            // the share sheet, which the simulator cannot deliver.
            if CommandLine.arguments.contains("-openLatest"), let url = store.latestBundle { opened = url }
            if CommandLine.arguments.contains("-scanLatest") { checking = true }
            if CommandLine.arguments.contains("-newReport") { Launch.shared.wantsNewReport = true }
            if launch.wantsNewReport { creating = true; launch.wantsNewReport = false }
        }
    }

    private func matches(_ report: Report) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty || report.address.localizedCaseInsensitiveContains(q)
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
