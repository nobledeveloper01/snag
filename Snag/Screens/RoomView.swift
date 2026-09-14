// Inside a room: what has been photographed, the prompts for what has not
// been looked at, and the shutter. A photograph is hashed the moment it
// arrives and the draft holds the hash; the caption and the snag-or-fine
// choice come after, on the item sheet. Until the seal an item can be
// edited or removed; after it, nothing.
import SwiftUI
import SnagDomain

struct RoomView: View {
    @Bindable var store: ReportStore
    let draftId: String
    let roomIndex: Int
    @Environment(\.colorScheme) private var scheme
    private var source: PhotoSource { PhotoSources.shared }
    @State private var pending: Pending?
    @State private var editing: Int?
    @State private var busy = false
    @State private var duplicate = false
    @State private var torchOn = false

    struct Pending: Identifiable { let id = UUID(); let hash: [UInt8]; let image: UIImage?; let prompt: String?; let issues: [Photo.Issue] }

    private var draft: ReportStore.Draft? { store.drafts.first { $0.id == draftId } }
    private var room: Room? { draft.flatMap { roomIndex < $0.report.rooms.count ? $0.report.rooms[roomIndex] : nil } }
    private var label: String { draft.map { $0.report.roomLabels[roomIndex].sentenceCased } ?? Strings.room }

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let room {
                List {
                    if room.items.isEmpty {
                        Text(Strings.roomEmptyHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                            .frame(minHeight: Target.standard)
                    }
                    ForEach(Array(room.items.enumerated()), id: \.offset) { i, item in
                        // A tap edits. Not a Button: the row stays the one
                        // element the audit read on the sealed screen, with
                        // the button trait and action added to it.
                        ItemRow(item: item, image: image(for: item.photoHash), palette: palette)
                            .onTapGesture { editing = i }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(Strings.edit)
                            .accessibilityAction { editing = i }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { remove(item: i) } label: { Label(Strings.delete, systemImage: "trash") }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listRoom()
            .listRoom()
            }
        }
        .pinned {
            VStack(alignment: .leading, spacing: Gap.s) {
                // The duplicate rule's answer, beside the shutter that was
                // pressed: a system alert's label does not scale with Dynamic
                // Type and the audit says so; a card does.
                if duplicate {
                    VStack(alignment: .leading, spacing: Gap.s) {
                        Text(Strings.alreadyPhotographedHint).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(Strings.ok) { duplicate = false }.buttonStyle(Secondary(palette: palette))
                    }
                    .padding(Gap.m)
                    .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
                    .padding(.horizontal, Gap.l)
                    .accessibilityIdentifier("duplicate")
                }
                // The prompts: one tap photographs with the caption started.
                // A strip, scrolled sideways, above the shutter.
                if let room {
                    Text(Strings.lookAt).font(Type.smallFont()).foregroundStyle(palette.textSecondary).padding(.horizontal, Gap.l)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Gap.s) {
                            ForEach(Prompts.forRoom(room.name), id: \.self) { prompt in
                                Button(prompt) { Task { await shoot(prompt: prompt) } }
                                    .buttonStyle(Chip(palette: palette))
                                    .disabled(busy)
                            }
                        }
                        .padding(.horizontal, Gap.l)
                    }
                    .accessibilityIdentifier("prompts")
                }
                HStack(spacing: Gap.s) {
                    Button {
                        Task { await shoot(prompt: nil) }
                    } label: {
                        Label(Strings.takePhoto, systemImage: "camera.fill")
                    }
                    .buttonStyle(Primary(palette: palette))
                    .disabled(busy)
                    if Torch.available {
                        Button {
                            Torch.toggle()
                            torchOn = Torch.isOn
                        } label: {
                            Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundStyle(torchOn ? palette.onAccent : palette.textPrimary)
                                .frame(width: Target.primary, height: Target.primary)
                                .background(torchOn ? palette.accent : palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
                        }
                        .accessibilityLabel(Strings.torch)
                        .accessibilityValue(torchOn ? Strings.on : Strings.off)
                    }
                }
                .padding(.horizontal, Gap.l)
            }
            .padding(.vertical, Gap.l)
        }
        .navigationTitle(label)
        .onAppear { store.resume = (draftId, roomIndex) }
        .sheet(item: $pending) { p in
            ItemSheet(image: p.image, palette: palette, initial: nil, prompt: p.prompt, issues: p.issues) { state, caption in
                guard var d = draft else { return }
                d.report.rooms[roomIndex].items.append(Item(state: state, photoHash: p.hash, caption: caption, takenAt: Clock.now()))
                store.update(d)
                pending = nil
            } cancel: {
                pending = nil
            }
        }
        .sheet(item: $editing) { i in
            if let room, i < room.items.count {
                let item = room.items[i]
                ItemSheet(image: image(for: item.photoHash), palette: palette, initial: item, prompt: nil, issues: []) { state, caption in
                    guard var d = draft else { return }
                    d.report.rooms[roomIndex].items[i].state = state
                    d.report.rooms[roomIndex].items[i].caption = caption
                    store.update(d)
                    editing = nil
                } cancel: {
                    editing = nil
                }
            }
        }
    }

    private func image(for hash: [UInt8]) -> UIImage? {
        UIImage(contentsOfFile: store.photoURL(draft: draftId, hash: hash).path)
    }

    private func remove(item i: Int) {
        guard var d = draft, i < d.report.rooms[roomIndex].items.count else { return }
        d.report.rooms[roomIndex].items.remove(at: i)
        store.update(d)
    }

    private func shoot(prompt: String?) async {
        guard let draft, !busy else { return }
        busy = true
        defer { busy = false }
        // The metadata comes off before anything else sees the bytes: what
        // is hashed and kept is the picture and nothing but the picture.
        guard let raw = await source.capture(), let data = Photo.strip(raw) else { return }
        let hash = SnagBundle.sha256(data)
        // One photograph is one item: the same bytes are refused before they
        // are written, so the draft never holds two claims about one moment.
        if draft.report.contains(photoHash: hash) {
            Haptics.refused()
            duplicate = true
            return
        }
        _ = store.store(photo: data, in: draft)
        Haptics.captured()
        pending = Pending(hash: hash, image: UIImage(data: data), prompt: prompt, issues: Photo.judge(data))
    }
}

/// A prompt chip: 56 pt tall so a thumb finds it, the raised surface.
struct Chip: ButtonStyle {
    let palette: Palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.secondaryFont())
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, Gap.m)
            .frame(minHeight: Target.standard)
            .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.chip))
            .opacity(configuration.isPressed ? 0.8 : 1)
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// After the shutter, and again on a tap before the seal: the photograph,
/// a sentence, snag or fine. Fine is a real answer — a report that only
/// lists what is wrong reads as a complaint. A prompt that asks for a
/// number — the meter, the keys — gets a field for it, and the number goes
/// into the caption in the tenant's own words.
struct ItemSheet: View {
    let image: UIImage?
    let palette: Palette
    let initial: Item?
    let prompt: String?
    let issues: [Photo.Issue]
    let done: (ItemState, String) -> Void
    let cancel: () -> Void
    @State private var caption: String
    @State private var state: ItemState
    @State private var reading = ""
    @State private var keys = 1

    init(image: UIImage?, palette: Palette, initial: Item?, prompt: String?, issues: [Photo.Issue], done: @escaping (ItemState, String) -> Void, cancel: @escaping () -> Void) {
        self.image = image; self.palette = palette; self.initial = initial; self.prompt = prompt; self.issues = issues; self.done = done; self.cancel = cancel
        let kind = Prompts.Kind.of(prompt)
        _caption = State(initialValue: initial?.caption ?? "")
        _state = State(initialValue: initial?.state ?? (kind == .plain ? .snag : .fine))
    }

    private var kind: Prompts.Kind { Prompts.Kind.of(prompt) }

    private var finalCaption: String {
        let note = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .plain:
            guard let prompt else { return note }
            return note.isEmpty ? prompt : prompt + " — " + note
        case .meter:
            let head = "\(prompt ?? Prompts.meter): \(reading.trimmingCharacters(in: .whitespaces)) \(prompt == Prompts.waterMeter ? Strings.cubicMetres : Strings.units)"
            return note.isEmpty ? head : head + " — " + note
        case .keys:
            let head = "\(Strings.keysHandedOver): \(keys)"
            return note.isEmpty ? head : head + " — " + note
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Gap.m) {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                            .accessibilityLabel(Strings.photograph)
                    }
                    // The judge's word, under the picture: a retake is Cancel
                    // and the shutter again, and the choice stays the tenant's.
                    ForEach(issues, id: \.self) { issue in
                        HStack(spacing: Gap.s) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(palette.snag).accessibilityHidden(true)
                            Text(issue == .dark ? Strings.tooDark : Strings.blurred).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        }
                        .frame(minHeight: Target.standard)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("issue")
                    }
                    if let prompt {
                        Text(prompt).font(Type.headlineFont()).foregroundStyle(palette.textPrimary)
                    }
                    if kind == .meter {
                        Text(Strings.reading).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        TextField("0000.0", text: $reading)
                            .keyboardType(.decimalPad)
                            .font(Type.headlineFont())
                            .padding(Gap.s)
                            .frame(minHeight: Target.standard)
                            .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.tile))
                            .accessibilityLabel(Strings.reading).accessibilityIdentifier("reading")
                    }
                    if kind == .keys {
                        Stepper(value: $keys, in: 0...20) {
                            Text("\(Strings.howMany): \(keys)").font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        }
                        .frame(minHeight: Target.standard)
                        .accessibilityIdentifier("keys")
                    }
                    Text(Strings.caption).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    TextEditor(text: $caption)
                        .font(Type.bodyFont())
                        .scrollContentBackground(.hidden)
                .listRoom()
            .listRoom()
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
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.done) { done(state, String(finalCaption.prefix(Canonical.maxCaption))) }
                        .buttonStyle(Primary(palette: palette))
                        .disabled(kind == .meter && reading.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(Strings.cancel) { cancel() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(initial == nil ? Strings.item : Strings.edit)
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
