// An address and a kind. Two fields, one button.
import SwiftUI
import SnagDomain

struct NewReportSheet: View {
    @Bindable var store: ReportStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var address = ""
    @State private var kind: Kind = .moveIn

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
            }
            .scrollContentBackground(.hidden)
            .background(LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Gap.s) {
                    Button(Strings.startWalk) {
                        store.newDraft(kind: kind, address: address.trimmingCharacters(in: .whitespaces), now: Clock.now())
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
        }
        .tint(palette.accent)
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
