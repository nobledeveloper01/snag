// The last look before the seal. Everything on this screen is what the
// signature will be over; nothing can be edited here, only gone back to.
import SwiftUI
import SnagDomain

struct ReviewView: View {
    @Bindable var store: ReportStore
    let draft: ReportStore.Draft
    @Binding var path: [Route]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var failure: String?

    var body: some View {
        let palette = Palette.current(scheme)
        let r = draft.report
        NavigationStack {
            List {
                Section {
                    Text(r.address).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                    Text("\(r.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(Dates.short(r.createdAt))").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    Text("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items) · \(r.snagCount) \(Strings.snags)")
                        .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
                Section {
                    ForEach(Array(r.rooms.enumerated()), id: \.offset) { _, room in
                        HStack {
                            Text(room.title).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            Spacer()
                            Text("\(room.items.filter { $0.state == .snag }.count) \(Strings.snags)").font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            TierChip(tier: room.tier, palette: palette)
                        }
                        .frame(minHeight: Target.standard)
                        .accessibilityElement(children: .combine)
                    }
                }
                Section {
                    Text(Strings.sealHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    if let failure {
                        Text(failure).font(Type.secondaryFont()).foregroundStyle(palette.snag)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listRoom()
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.seal) { seal() }.buttonStyle(Primary(palette: palette))
                    Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.review)
        }
        .tint(palette.accent)
    }

    private func seal() {
        do {
            let sealed = try store.seal(draft, with: try Sealer())
            Haptics.sealed()
            dismiss()
            path = [.sealed(sealed.id)]
        } catch {
            failure = Strings.sealFailed
        }
    }
}

enum Dates {
    static func short(_ seconds: Int64) -> String {
        Date(timeIntervalSince1970: TimeInterval(seconds)).formatted(date: .abbreviated, time: .shortened)
    }
}
