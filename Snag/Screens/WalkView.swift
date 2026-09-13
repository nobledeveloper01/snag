// The walk: rooms, then items. Phase 0 has the rooms; Phase 1 brings the
// camera, the items and the seal. One primary action, pinned.
import SwiftUI
import SnagDomain

struct WalkView: View {
    @Bindable var store: ReportStore
    let draftId: Int
    @Environment(\.colorScheme) private var scheme
    @State private var adding = false
    @State private var name: RoomName = .livingRoom
    @State private var custom = ""

    private var draft: ReportStore.Draft? { store.drafts.first { $0.id == draftId } }

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let draft {
                List {
                    Section {
                        ForEach(Array(draft.report.rooms.enumerated()), id: \.offset) { i, room in
                            HStack {
                                Text(room.name == .other ? (room.custom ?? Strings.room) : room.name.word.capitalized)
                                    .font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                                Spacer()
                                TierChip(tier: room.tier, palette: palette)
                            }
                            .frame(minHeight: Target.standard)
                            .accessibilityElement(children: .combine)
                        }
                    } header: {
                        Text(draft.report.address).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(Strings.addRoom) { adding = true }
                .buttonStyle(Primary(palette: Palette.current(scheme)))
                .padding(Gap.l)
        }
        .navigationTitle(draft.map { "\($0.report.rooms.count) \(Strings.room.lowercased())s" } ?? Strings.room)
        .sheet(isPresented: $adding) {
            let palette = Palette.current(scheme)
            NavigationStack {
                List {
                    ForEach(RoomName.allCases, id: \.self) { candidate in
                        Button {
                            name = candidate
                        } label: {
                            HStack {
                                Text(candidate.word.capitalized).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                                Spacer()
                                if candidate == name {
                                    Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(palette.accent).accessibilityHidden(true)
                                }
                            }
                            .frame(minHeight: Target.standard).contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(candidate == name ? .isSelected : [])
                    }
                    if name == .other {
                        TextField(Strings.roomNamePlaceholder, text: $custom).font(Type.bodyFont()).frame(minHeight: Target.standard)
                            .accessibilityLabel(Strings.room)
                    }
                }
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Button(Strings.addRoom) {
                        guard var d = draft else { return }
                        d.report.rooms.append(Room(name: name, custom: name == .other ? custom : nil))
                        store.update(d)
                        adding = false
                    }
                    .buttonStyle(Primary(palette: palette))
                    .disabled(name == .other && custom.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(Gap.l)
                }
                .navigationTitle(Strings.addRoom)
            }
            .tint(palette.accent)
        }
    }
}

/// The chip that follows every number and every room: photographed,
/// measured, scanned. Never coloured; the word carries it.
struct TierChip: View {
    let tier: Tier
    let palette: Palette
    var body: some View {
        Text(tier.word)
            .font(Type.smallFont())
            .foregroundStyle(palette.textSecondary)
            .padding(.horizontal, Gap.s).padding(.vertical, Gap.xs)
            .background(palette.high, in: RoundedRectangle(cornerRadius: Radius.chip))
            .accessibilityLabel(tier.word)
    }
}
