// A sealed report: its id, whether its own bundle still verifies, and the
// two ways it leaves the phone. The status line is not remembered — the
// verifier runs every time the screen appears, over the files on disk.
import SwiftUI
import SnagDomain

struct SealedView: View {
    @Bindable var store: ReportStore
    let sealed: ReportStore.Sealed
    @Environment(\.colorScheme) private var scheme
    @State private var verdict: Verdict?
    @State private var pdf: URL?

    var body: some View {
        let palette = Palette.current(scheme)
        let r = sealed.report
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            List {
                Section {
                    Text(r.address).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                    Text("\(r.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(Dates.short(r.createdAt)), \(Strings.datedByPhone)")
                        .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    Text("\(r.snagCount) \(Strings.snags) · \(r.tier.word)").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
                Section {
                    VerdictRow(verdict: verdict, palette: palette)
                    VStack(alignment: .leading, spacing: Gap.xs) {
                        Text(Strings.reportId).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        Text(sealed.id).font(Type.smallFont().monospaced()).foregroundStyle(palette.textPrimary)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: Target.standard)
                    .accessibilityElement(children: .combine)
                }
                Section {
                    NavigationLink {
                        ReportDetailView(report: r, bundle: sealed.url)
                    } label: {
                        Text("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items)").font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            .frame(minHeight: Target.standard)
                    }
                    .accessibilityIdentifier("rooms")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Gap.s) {
                if let pdf {
                    ShareLink(item: pdf) { Text(Strings.sharePDF).frame(maxWidth: .infinity) }.buttonStyle(Primary(palette: palette))
                } else {
                    Button(Strings.sharePDF) {}.buttonStyle(Primary(palette: palette)).disabled(true)
                }
                ShareLink(item: sealed.url) { Text(Strings.shareBundle).frame(maxWidth: .infinity) }.buttonStyle(Secondary(palette: palette))
            }
            .padding(Gap.l)
        }
        .navigationTitle(Strings.sealed)
        .task {
            // `-tamper` flips one byte of the signed bytes before the verifier
            // runs. It exists so the UI test can see the word "Altered" on a
            // real screen, and it is a launch argument, not a build flag,
            // because the tested app must be the shipped app.
            if CommandLine.arguments.contains("-tamper") {
                let f = sealed.url.appendingPathComponent(SnagBundle.reportFile)
                if var d = try? Data(contentsOf: f), !d.isEmpty { d[d.count - 1] ^= 0x01; try? d.write(to: f) }
            }
            verdict = Verifier.verify(sealed.url)
            pdf = try? ReportPDF.write(sealed)
        }
    }
}

/// One line, one word that matters: unaltered or altered. An icon beside
/// it, so the colour is never the only carrier.
struct VerdictRow: View {
    let verdict: Verdict?
    let palette: Palette
    var body: some View {
        HStack(spacing: Gap.sm) {
            switch verdict {
            case .unaltered:
                Image(systemName: "checkmark.seal.fill").foregroundStyle(palette.fine).accessibilityHidden(true)
                Text(Strings.unaltered).font(Type.headlineFont()).foregroundStyle(palette.textPrimary)
            case .altered, .notABundle:
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(palette.snag).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Gap.xs) {
                    Text(Strings.altered).font(Type.headlineFont()).foregroundStyle(palette.textPrimary)
                    Text(Strings.alteredHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
            case nil:
                ProgressView().accessibilityHidden(true)
                Text(Strings.checking).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
            }
        }
        .frame(minHeight: Target.standard)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("verdict")
    }
}
