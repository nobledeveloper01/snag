// The walk: rooms, then items. Tap a room to photograph in it; Review when
// there is something to seal. One primary action, pinned.
import SwiftUI
import SnagDomain

struct WalkView: View {
    @Bindable var store: ReportStore
    let draftId: String
    @Binding var path: [Route]
    @Environment(\.colorScheme) private var scheme
    @State private var adding = false
    @State private var reviewing = false
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
                            NavigationLink {
                                RoomView(store: store, draftId: draftId, roomIndex: i)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: Gap.xs) {
                                        Text(room.title).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                                        Text("\(room.items.count) \(Strings.items) · \(room.items.filter { $0.state == .snag }.count) \(Strings.snags)")
                                            .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                                    }
                                    Spacer()
                                    TierChip(tier: room.tier, palette: palette)
                                }
                                .frame(minHeight: Target.standard)
                            }
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
            VStack(spacing: Gap.s) {
                Button(Strings.addRoom) { adding = true }
                    .buttonStyle(Primary(palette: Palette.current(scheme)))
                if (draft?.report.itemCount ?? 0) > 0 {
                    Button(Strings.review) { reviewing = true }
                        .buttonStyle(Secondary(palette: Palette.current(scheme)))
                }
            }
            .padding(Gap.l)
        }
        .navigationTitle(draft.map { "\($0.report.rooms.count) \(Strings.room.lowercased())s" } ?? Strings.room)
        .sheet(isPresented: $adding) { addRoomSheet }
        .sheet(isPresented: $reviewing) {
            if let draft { ReviewView(store: store, draft: draft, path: $path) }
        }
    }

    private var addRoomSheet: some View {
        let palette = Palette.current(scheme)
        return NavigationStack {
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
                .accessibilityIdentifier("addRoomConfirm")
                .disabled(name == .other && custom.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(Gap.l)
            }
            .navigationTitle(Strings.addRoom)
        }
        .tint(palette.accent)
    }
}

extension Room {
    var title: String { name == .other ? (custom ?? Strings.room) : name.word.capitalized }
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
