// The few things a tenant can set, and the two things an agent's phone
// wants: a lock, and a backup.
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var store: ReportStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var prefs = Preferences.shared
    @State private var backup: URL?
    @State private var importing = false
    @State private var restored: (kept: Int, refused: Int)?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Binding(get: { prefs.lock }, set: { prefs.lock = $0 })) {
                        VStack(alignment: .leading, spacing: Gap.xs) {
                            Text(Strings.lockTitle).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            Text(AppLock.canLock ? Strings.lockHint : Strings.lockUnavailable).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        }
                    }
                    .frame(minHeight: Target.standard)
                    .disabled(!AppLock.canLock && !prefs.lock)
                    .accessibilityIdentifier("lock")
                    Toggle(isOn: Binding(get: { prefs.nudge }, set: { prefs.nudge = $0 })) {
                        VStack(alignment: .leading, spacing: Gap.xs) {
                            Text(Strings.nudgeTitle).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            Text(Strings.nudgeSetting).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        }
                    }
                    .frame(minHeight: Target.standard)
                    .accessibilityIdentifier("nudge")
                }
                Section {
                    Text(Strings.backupHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    if let backup {
                        ShareLink(item: backup) { Text("\(Strings.backup) (\(store.sealed.count))").frame(maxWidth: .infinity) }
                            .buttonStyle(Secondary(palette: palette))
                            .disabled(store.sealed.isEmpty)
                    }
                    Button(Strings.restore) { importing = true }.buttonStyle(Secondary(palette: palette))
                    if let restored {
                        Text("\(Strings.restored) \(restored.kept) · \(Strings.refused) \(restored.refused)")
                            .font(Type.bodyFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                            .accessibilityIdentifier("restored")
                    }
                } header: {
                    Text(Strings.backupHeader).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .listRoom()
            .pinned {
                Button(Strings.done) { dismiss() }.buttonStyle(Primary(palette: palette)).padding(Gap.l)
            }
            .navigationTitle(Strings.settings)
            .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(exportedAs: "ng.snag.backup"), .zip, .data]) { result in
                guard case .success(let url) = result else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) { restored = try? Backup.restore(data, into: store) }
            }
        }
        .tint(palette.accent)
        .task { backup = try? Backup.write(store) }
    }
}
