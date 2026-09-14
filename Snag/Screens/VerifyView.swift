// A bundle opened from outside — a landlord's phone, a mail attachment, a
// file the tenant kept. The verifier runs, and the screen says one of two
// things. The report is shown either way, under the verdict.
import SwiftUI
import SnagDomain

struct VerifyView: View {
    let url: URL
    var store: ReportStore? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var verdict: Verdict?
    @State private var dir: URL?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            List {
                Section { VerdictRow(verdict: verdict, palette: palette) }
                if case .unaltered(let r, let counter) = verdict {
                    Section {
                        Text(r.address).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                        Text("\(r.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(Dates.short(r.createdAt)), \(Strings.datedByPhone)")
                            .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        Text("\(r.snagCount) \(Strings.snags) · \(r.tier.word)").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        if let counter {
                            Text("\(Strings.counterSigned) \(counter.name), \(Dates.short(counter.signedAt))").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        }
                        if let a = dir.flatMap({ Verifier.amendment(in: $0) }) {
                            Text("\(Strings.amendedOn) \(Dates.short(a.amendedAt))").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        }
                    }
                    // Compare two bundles: the opened move-out against the
                    // move-in this phone holds — on any phone that holds it.
                    if let movedIn = store?.movedIn(for: r) {
                        ChangesSection(lines: Changes.lines(movedIn: movedIn.report, movedOut: r), palette: palette)
                    }
                    Section {
                        NavigationLink {
                            ReportDetailView(report: r, bundle: dir ?? url)
                        } label: {
                            Text("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items)").font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                                .frame(minHeight: Target.standard)
                        }
                        .accessibilityIdentifier("rooms")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listRoom()
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .pinned {
                Button(Strings.done) { dismiss() }.buttonStyle(Primary(palette: palette)).padding(Gap.l)
            }
            .navigationTitle(Strings.verifyTitle)
        }
        .tint(palette.accent)
        .task {
            let scoped = url.startAccessingSecurityScopedResource()
            let opened = Verifier.open(url)
            verdict = opened.verdict
            dir = opened.dir
            if scoped { url.stopAccessingSecurityScopedResource() }
        }
    }
}
