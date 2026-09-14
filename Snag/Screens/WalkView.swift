// The walk: rooms, then items. Tap a room to photograph in it; Review when
// there is something to seal. Rooms can be renamed, reordered and removed
// until the seal; after it, nothing. One primary action, pinned.
import SwiftUI
import SnagDomain

struct WalkView: View {
    @Bindable var store: ReportStore
    let draftId: String
    @Binding var path: [Route]
    @Environment(\.colorScheme) private var scheme
    @State private var adding = false
    @State private var renaming: Int?
    @State private var reviewing = false
    @State private var reordering = false

    private var draft: ReportStore.Draft? { store.drafts.first { $0.id == draftId } }

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let draft {
                let labels = draft.report.roomLabels
                List {
                    Section {
                        ForEach(Array(draft.report.rooms.enumerated()), id: \.offset) { i, room in
                            NavigationLink(value: Route.room(draftId, i)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: Gap.xs) {
                                        Text(labels[i].sentenceCased).font(Type.titleFont()).foregroundStyle(palette.textPrimary)
                                        Text("\(room.items.count) \(Strings.items) · \(room.items.filter { $0.state == .snag }.count) \(Strings.snags)")
                                            .font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                                    }
                                    Spacer()
                                    TierChip(tier: room.tier, palette: palette)
                                }
                                .frame(minHeight: Target.standard)
                            }
                            .accessibilityElement(children: .combine)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { remove(room: i) } label: { Label(Strings.delete, systemImage: "trash") }
                                Button { renaming = i } label: { Label(Strings.rename, systemImage: "pencil") }.tint(palette.accent)
                            }
                        }
                        .onMove { from, to in
                            guard var d = self.draft else { return }
                            d.report.rooms.move(fromOffsets: from, toOffset: to)
                            store.update(d)
                        }
                    } header: {
                        Text(draft.report.address).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRoom()
            .listRoom()
                .environment(\.editMode, .constant(reordering ? .active : .inactive))
            }
        }
        .pinned {
            VStack(spacing: Gap.s) {
                Button(Strings.addRoom) { adding = true }
                    .buttonStyle(Primary(palette: Palette.current(scheme)))
                HStack(spacing: Gap.s) {
                    if (draft?.report.rooms.count ?? 0) > 1 {
                        Button(reordering ? Strings.doneReordering : Strings.reorder) { reordering.toggle() }
                            .buttonStyle(Secondary(palette: Palette.current(scheme)))
                    }
                    if (draft?.report.itemCount ?? 0) > 0 {
                        Button(Strings.review) { reviewing = true }
                            .buttonStyle(Secondary(palette: Palette.current(scheme)))
                    }
                }
            }
            .padding(Gap.l)
        }
        .navigationTitle(draft.map { "\($0.report.rooms.count) \(Strings.room.lowercased())s" } ?? Strings.room)
        .onAppear { if store.resume?.draft == draftId { store.resume = nil } }
        .sheet(isPresented: $adding) {
            RoomNameSheet(title: Strings.addRoom, initial: .livingRoom, initialCustom: "") { name, custom in
                guard var d = draft else { return }
                d.report.rooms.append(Room(name: name, custom: custom))
                store.update(d)
            }
        }
        .sheet(item: $renaming) { i in
            if let draft, i < draft.report.rooms.count {
                let room = draft.report.rooms[i]
                RoomNameSheet(title: Strings.rename, initial: room.name, initialCustom: room.custom ?? "") { name, custom in
                    guard var d = self.draft else { return }
                    d.report.rooms[i].name = name
                    d.report.rooms[i].custom = name == .other ? custom : nil
                    store.update(d)
                }
            }
        }
        .sheet(isPresented: $reviewing) {
            if let draft { ReviewView(store: store, draft: draft, path: $path) }
        }
    }

    private func remove(room i: Int) {
        guard var d = draft, i < d.report.rooms.count else { return }
        d.report.rooms.remove(at: i)
        store.update(d)
    }
}

extension Int: @retroactive Identifiable { public var id: Int { self } }

/// Naming a room, for adding one and for renaming one: the nine names as
/// rows, and a field when the name is the tenant's own.
struct RoomNameSheet: View {
    let title: String
    let initial: RoomName
    let initialCustom: String
    let done: (RoomName, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var name: RoomName
    @State private var custom: String

    init(title: String, initial: RoomName, initialCustom: String, done: @escaping (RoomName, String?) -> Void) {
        self.title = title; self.initial = initial; self.initialCustom = initialCustom; self.done = done
        _name = State(initialValue: initial); _custom = State(initialValue: initialCustom)
    }

    var body: some View {
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
            .listRoom()
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(title) {
                        done(name, name == .other ? custom.trimmingCharacters(in: .whitespaces) : nil)
                        dismiss()
                    }
                    .buttonStyle(Primary(palette: palette))
                    .accessibilityIdentifier("addRoomConfirm")
                    .disabled(name == .other && custom.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(title)
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
