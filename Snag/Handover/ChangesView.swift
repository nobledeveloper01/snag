// What changed between move-in and move-out, item by item, in the words
// the domain uses — same, changed, new, not photographed this time — and
// never what it costs.
import SwiftUI
import SnagDomain

struct ChangeLine: Identifiable {
    let id: Int
    let room: String
    let text: String
    let word: String
}

enum Changes {
    static func lines(movedIn: Report, movedOut: Report) -> [ChangeLine] {
        let labels = movedIn.roomLabels
        return Compare.diff(movedIn: movedIn, movedOut: movedOut).enumerated().map { i, change in
            switch change {
            case .same(let r, let item):
                return ChangeLine(id: i, room: labels[r].sentenceCased, text: caption(movedIn.rooms[r].items[item]), word: Strings.changeSame)
            case .changed(let r, _, let from, let to):
                let states = from.state == to.state ? "" : " (\(from.state == .snag ? Strings.snag : Strings.fine) → \(to.state == .snag ? Strings.snag : Strings.fine))"
                return ChangeLine(id: i, room: labels[r].sentenceCased, text: caption(from) + states, word: Strings.changeChanged)
            case .added(let r, let item):
                return ChangeLine(id: i, room: r < labels.count ? labels[r].sentenceCased : Strings.room, text: caption(item), word: Strings.changeAdded)
            case .missing(let r, let item):
                return ChangeLine(id: i, room: labels[r].sentenceCased, text: caption(item), word: Strings.changeMissing)
            }
        }
    }
    private static func caption(_ item: Item) -> String { item.caption.isEmpty ? Strings.noCaption : item.caption }
}

struct ChangesSection: View {
    let lines: [ChangeLine]
    let palette: Palette
    var body: some View {
        Section {
            ForEach(lines) { line in
                VStack(alignment: .leading, spacing: Gap.xs) {
                    Text("\(line.room) · \(line.text)").font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                    Text(line.word).font(Type.smallFont()).foregroundStyle(line.word == Strings.changeSame ? palette.fine : palette.altered)
                }
                .frame(minHeight: Target.standard)
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text(Strings.sinceMoveIn).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
        }
        .accessibilityIdentifier("changes")
    }
}
