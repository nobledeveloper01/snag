// Inside a room: what has been photographed, and the shutter. A photograph
// is hashed the moment it arrives and the draft holds the hash; the caption
// and the snag-or-fine choice come after, on the item sheet.
import SwiftUI
import SnagDomain

struct RoomView: View {
    @Bindable var store: ReportStore
    let draftId: String
    let roomIndex: Int
    @Environment(\.colorScheme) private var scheme
    @State private var source: PhotoSource = PhotoSources.make()
    @State private var pending: Pending?
    @State private var busy = false

    struct Pending: Identifiable { let id = UUID(); let hash: [UInt8]; let image: UIImage? }

    private var draft: ReportStore.Draft? { store.drafts.first { $0.id == draftId } }
    private var room: Room? { draft.flatMap { roomIndex < $0.report.rooms.count ? $0.report.rooms[roomIndex] : nil } }

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let room {
                if room.items.isEmpty {
                    ScrollView {
                        Text(Strings.roomEmptyHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center).padding(Gap.xl).frame(maxWidth: .infinity)
                    }
                } else {
                    List {
                        ForEach(Array(room.items.enumerated()), id: \.offset) { _, item in
                            ItemRow(item: item, image: image(for: item.photoHash), palette: palette)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await shoot() }
            } label: {
                Label(Strings.takePhoto, systemImage: "camera.fill")
            }
            .buttonStyle(Primary(palette: palette))
            .disabled(busy)
            .padding(Gap.l)
        }
        .navigationTitle(room?.title ?? Strings.room)
        .sheet(item: $pending) { p in
            ItemSheet(image: p.image, palette: palette) { state, caption in
                guard var d = draft else { return }
                d.report.rooms[roomIndex].items.append(Item(state: state, photoHash: p.hash, caption: caption, takenAt: Clock.now()))
                store.update(d)
                pending = nil
            } cancel: {
                pending = nil
            }
        }
    }

    private func image(for hash: [UInt8]) -> UIImage? {
        UIImage(contentsOfFile: store.photoURL(draft: draftId, hash: hash).path)
    }

    private func shoot() async {
        guard let draft, !busy else { return }
        busy = true
        defer { busy = false }
        guard let data = await source.capture() else { return }
        let hash = store.store(photo: data, in: draft)
        pending = Pending(hash: hash, image: UIImage(data: data))
    }
}

struct ItemRow: View {
    let item: Item
    let image: UIImage?
    let palette: Palette
    var body: some View {
        HStack(spacing: Gap.sm) {
            Group {
                if let image { Image(uiImage: image).resizable().scaledToFill() } else { palette.high }
            }
            .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: Radius.tile))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Gap.xs) {
                Text(item.caption.isEmpty ? Strings.noCaption : item.caption).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                Text(item.state == .snag ? Strings.snag : Strings.fine)
                    .font(Type.smallFont())
                    .foregroundStyle(item.state == .snag ? palette.snag : palette.fine)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: Target.standard)
        .accessibilityElement(children: .combine)
    }
}

/// After the shutter: the photograph, a sentence, snag or fine. Fine is a
/// real answer — a report that only lists what is wrong reads as a complaint.
struct ItemSheet: View {
    let image: UIImage?
    let palette: Palette
    let done: (ItemState, String) -> Void
    let cancel: () -> Void
    @State private var caption = ""
    @State private var state: ItemState = .snag

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Gap.m) {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                            .accessibilityLabel(Strings.photograph)
                    }
                    Text(Strings.caption).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    TextEditor(text: $caption)
                        .font(Type.bodyFont())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: Target.standard)
                        .padding(Gap.s)
                        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.tile))
                        .accessibilityLabel(Strings.caption).accessibilityIdentifier("caption")
                        .onChange(of: caption) { _, new in if new.count > Canonical.maxCaption { caption = String(new.prefix(Canonical.maxCaption)) } }
                    HStack(spacing: Gap.s) {
                        ChoiceRow(title: Strings.snag, selected: state == .snag, palette: palette) { state = .snag }
                        ChoiceRow(title: Strings.fine, selected: state == .fine, palette: palette) { state = .fine }
                    }
                }
                .padding(Gap.l)
            }
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Gap.s) {
                    Button(Strings.done) { done(state, caption.trimmingCharacters(in: .whitespacesAndNewlines)) }
                        .buttonStyle(Primary(palette: palette))
                    Button(Strings.cancel) { cancel() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.item)
        }
        .tint(palette.accent)
        .interactiveDismissDisabled()
    }
}

/// An owned two-way choice, because a segmented picker's value text does not
/// scale with Dynamic Type and the audit says so.
struct ChoiceRow: View {
    let title: String
    let selected: Bool
    let palette: Palette
    let act: () -> Void
    var body: some View {
        Button(action: act) {
            Text(title).font(Type.headlineFont())
                .foregroundStyle(selected ? palette.onAccent : palette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: Target.standard)
                .background(selected ? palette.accent : palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
                .contentShape(Rectangle())
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
