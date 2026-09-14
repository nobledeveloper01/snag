// The rooms and items of a report that can no longer be edited — a sealed
// one, or one opened from outside. No pinned action: this screen is for
// reading, and a long report scrolls to its end.
import SwiftUI
import SnagDomain

struct ReportDetailView: View {
    let report: Report
    let bundle: URL
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.current(scheme)
        List {
            ForEach(Array(report.rooms.enumerated()), id: \.offset) { _, room in
                Section {
                    if room.items.isEmpty {
                        Text(Strings.noItems).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary).frame(minHeight: Target.standard)
                    }
                    ForEach(Array(room.items.enumerated()), id: \.offset) { _, item in
                        ItemRow(item: item, image: UIImage(contentsOfFile: SnagBundle.photoURL(in: bundle, hash: item.photoHash).path), palette: palette)
                    }
                } header: {
                    HStack {
                        Text(room.title).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        Spacer()
                        TierChip(tier: room.tier, palette: palette)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .navigationTitle("\(report.rooms.count) \(Strings.room.lowercased())s")
    }
}
