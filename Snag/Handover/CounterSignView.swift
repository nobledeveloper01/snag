// The other party, on the tenant's phone, in front of the tenant: a name,
// a number, a signature drawn on glass. Sealed as the second layer with the
// same key, and the bundle verifies as a whole from then on.
import SwiftUI
import SnagDomain

struct CounterSignView: View {
    @Bindable var store: ReportStore
    let sealed: ReportStore.Sealed
    let done: (ReportStore.Sealed) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var name = ""
    @State private var phone = ""
    @State private var strokes: [[CGPoint]] = []
    @State private var failure: String?
    @FocusState private var focus: Field?
    enum Field { case name, phone }

    static let padSize = CGSize(width: 340, height: 160)

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Gap.m) {
                    Text(Strings.counterSignHint).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
                    Text(Strings.name).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    TextField(Strings.name, text: $name).font(Type.bodyFont())
                        .padding(Gap.s).frame(minHeight: Target.standard)
                        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.tile))
                        .accessibilityLabel(Strings.name).accessibilityIdentifier("name")
                        .focused($focus, equals: .name)
                    Text(Strings.phone).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    TextField(Strings.phone, text: $phone).font(Type.bodyFont()).keyboardType(.phonePad)
                        .padding(Gap.s).frame(minHeight: Target.standard)
                        .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.tile))
                        .accessibilityLabel(Strings.phone).accessibilityIdentifier("phone")
                        .focused($focus, equals: .phone)
                    HStack {
                        Text(Strings.signHere).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        Spacer()
                        Button(Strings.clear) { strokes = [] }.font(Type.secondaryFont()).frame(minHeight: Target.standard)
                            .disabled(strokes.isEmpty)
                    }
                    SignaturePad(strokes: $strokes, palette: palette)
                        .frame(height: Self.padSize.height)
                        .accessibilityIdentifier("pad")
                    if let failure {
                        Text(failure).font(Type.secondaryFont()).foregroundStyle(palette.snag)
                    }
                }
                .padding(Gap.l)
            }
            .scrollDismissesKeyboard(.immediately)
            // A way off the keyboard, because the pad is under it.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(Strings.done) { focus = nil }.accessibilityIdentifier("keyboardDone")
                }
            }
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.counterSign) { sign() }
                        .buttonStyle(Primary(palette: palette))
                        .accessibilityIdentifier("signConfirm")
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || strokes.isEmpty)
                    Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.counterSign)
        }
        .tint(palette.accent)
        .interactiveDismissDisabled()
    }

    private func sign() {
        do {
            guard let image = SignaturePad.image(of: strokes, size: Self.padSize) else { throw SealFailure.image }
            let updated = try store.counterSign(sealed, name: name.trimmingCharacters(in: .whitespaces), phone: phone.trimmingCharacters(in: .whitespaces),
                                                signature: image, with: try Sealer(), now: Clock.now())
            Haptics.sealed()
            done(updated)
            dismiss()
        } catch {
            failure = Strings.sealFailed
        }
    }

    enum SealFailure: Error { case image }
}
