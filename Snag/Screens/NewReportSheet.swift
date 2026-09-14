// An address and a kind. Two fields, one button.
import SwiftUI
import SnagDomain

struct NewReportSheet: View {
    @Bindable var store: ReportStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var address = ""
    @State private var kind: Kind = .moveIn
    @State private var template: RoomTemplate? = .oneBed
    @State private var movedIn: ReportStore.Sealed?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            List {
                // Grows to three lines: an address is long, and large text is larger.
                // A TextEditor, not a TextField: a vertical TextField's inner view
                // sizes to its content whatever frame it is given, and the audit
                // measures that inner view. An editor owns its frame, so the
                // thing a finger lands on is 56 pt.
                ZStack(alignment: .topLeading) {
                    if address.isEmpty {
                        Text(Strings.addressPlaceholder).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                            .padding(.top, 8).padding(.leading, 5).accessibilityHidden(true)
                    }
                    TextEditor(text: $address)
                        .font(Type.bodyFont())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: Target.standard)
                        .accessibilityLabel(Strings.address).accessibilityIdentifier("address")
                }
                    .accessibilityLabel(Strings.address).accessibilityIdentifier("address")
                Picker(Strings.kind, selection: $kind) {
                    Text(Strings.moveIn).tag(Kind.moveIn)
                    Text(Strings.moveOut).tag(Kind.moveOut)
                }
                .pickerStyle(.inline).font(Type.bodyFont())
                // A move-out linked to a move-in starts with the move-in's rooms
                // and can shoot the same views; the link goes in the report.
                if kind == .moveOut, !store.sealed.filter({ $0.report.kind == .moveIn }).isEmpty {
                    Section {
                        ForEach(store.sealed.filter { $0.report.kind == .moveIn }) { s in
                            TemplateRow(title: s.report.address, detail: Dates.short(s.report.createdAt), selected: movedIn?.id == s.id, palette: palette) { movedIn = s }
                        }
                        TemplateRow(title: Strings.noLink, detail: nil, selected: movedIn == nil, palette: palette) { movedIn = nil }
                    } header: {
                        Text(Strings.linkMoveIn).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    }
                }
                // The flat's shape names the rooms before the walk starts; the
                // tenant adds or removes from there. Owned rows, not a picker:
                // a picker's value text does not scale.
                if movedIn == nil {
                Section {
                    ForEach(RoomTemplate.allCases, id: \.self) { t in
                        TemplateRow(title: t.word.sentenceCased, detail: "\(t.rooms.count) \(Strings.room.lowercased())s", selected: template == t, palette: palette) { template = t }
                    }
                    TemplateRow(title: Strings.emptyFlat, detail: nil, selected: template == nil, palette: palette) { template = nil }
                } header: {
                    Text(Strings.startWith).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
                }
            }
            .scrollContentBackground(.hidden)
            .listRoom()
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.startWalk) {
                        store.newDraft(kind: kind, address: address.trimmingCharacters(in: .whitespaces), now: Clock.now(), template: template, movedIn: kind == .moveOut ? movedIn : nil)
                        dismiss()
                    }
                    .buttonStyle(Primary(palette: palette))
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                    // A row, not a toolbar item: toolbar items are sized by the
                    // bar and stop scaling at the largest text sizes.
                    Button {
                        dismiss()
                    } label: {
                        Text(Strings.cancel)
                            .font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: Target.standard)
                            .contentShape(Rectangle())
                    }
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.newReport)
            .onChange(of: movedIn) { _, new in if let new, address.trimmingCharacters(in: .whitespaces).isEmpty { address = new.report.address } }
        }
        .tint(palette.accent)
    }
}

extension String {
    /// "two bedroom" → "Two bedroom". `capitalized` would give "Two Bedroom".
    var sentenceCased: String { prefix(1).uppercased() + dropFirst() }
}

struct TemplateRow: View {
    let title: String
    let detail: String?
    let selected: Bool
    let palette: Palette
    let act: () -> Void
    var body: some View {
        Button(action: act) {
            HStack {
                Text(title).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                Spacer()
                if let detail { Text(detail).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary) }
                if selected {
                    Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(palette.accent).accessibilityHidden(true)
                }
            }
            .frame(minHeight: Target.standard).contentShape(Rectangle())
        }
        .accessibilityIdentifier(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The clock, as the domain wants it: seconds since 1970, the phone's own,
/// and a launch argument to pin it for the UI tests.
enum Clock {
    static func now() -> Int64 {
        if let i = CommandLine.arguments.firstIndex(of: "-now"), i + 1 < CommandLine.arguments.count, let n = Int64(CommandLine.arguments[i + 1]) { return n }
        return Int64(Date().timeIntervalSince1970)
    }
}
