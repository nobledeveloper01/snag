// A bundle opened from outside — a landlord's phone, a mail attachment, a
// file the tenant kept. The verifier runs, and the screen says one of two
// things. The report is shown either way, under the verdict.
import SwiftUI
import SnagDomain

struct VerifyView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var verdict: Verdict?

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
                    }
                    Section {
                        NavigationLink {
                            ReportDetailView(report: r, bundle: url)
                        } label: {
                            Text("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items)").font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                                .frame(minHeight: Target.standard)
                        }
                        .accessibilityIdentifier("rooms")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button(Strings.done) { dismiss() }.buttonStyle(Primary(palette: palette)).padding(Gap.l)
            }
            .navigationTitle(Strings.verifyTitle)
        }
        .tint(palette.accent)
        .task {
            let scoped = url.startAccessingSecurityScopedResource()
            verdict = Verifier.verify(url)
            if scoped { url.stopAccessingSecurityScopedResource() }
        }
    }
}
