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
    @State private var language = L10n.language
    @State private var syncing = false
    @State private var synced: String?

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            List {
                // The language, chosen here and not by the phone: a tenant whose
                // phone is in English may still want the walk in Naijá.
                Section {
                    ForEach(Language.allCases, id: \.self) { l in
                        TemplateRow(title: l.name, detail: nil, selected: language == l, palette: palette) {
                            L10n.language = l
                            language = l
                        }
                        .accessibilityIdentifier("lang-\(l.rawValue)")
                    }
                    if language != .english {
                        Text(Strings.translationDraft).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    }
                } header: {
                    Text(Strings.language).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
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
                // The tenant's own iCloud, off until asked; each bundle verified on the way down.
                Section {
                    Toggle(isOn: Binding(get: { prefs.cloud }, set: { prefs.cloud = $0 })) {
                        VStack(alignment: .leading, spacing: Gap.xs) {
                            Text(Strings.cloudTitle).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                            Text(Strings.cloudHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                        }
                    }
                    .frame(minHeight: Target.standard)
                    .accessibilityIdentifier("cloud")
                    if prefs.cloud {
                        Button(Strings.syncNow) { sync() }.buttonStyle(Secondary(palette: palette)).disabled(syncing)
                            .accessibilityIdentifier("syncNow")
                        if let synced {
                            Text(synced).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary).frame(minHeight: Target.standard)
                                .accessibilityIdentifier("synced")
                        }
                    }
                } header: {
                    Text(Strings.cloudHeader).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
                Section {
                    Text(Strings.backupHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                    // A ShareLink only when there is something to share: a
                    // disabled one is read by the audit as clipped text.
                    if let backup, !store.sealed.isEmpty {
                        ShareLink(item: backup) { Text("\(Strings.backup) (\(store.sealed.count))").frame(maxWidth: .infinity) }
                            .buttonStyle(Secondary(palette: palette))
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
                    .accessibilityIdentifier("settingsDone")
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

    private func sync() {
        syncing = true
        Task {
            defer { syncing = false }
            guard await PrivateCloud.available() else { synced = Strings.cloudSignIn; return }
            do {
                let o = try await CloudMirror.sync(store, with: PrivateCloud())
                synced = "\(Strings.cloudUp) \(o.pushed) · \(Strings.cloudDown) \(o.pulled) · \(Strings.refused) \(o.refused)"
            } catch {
                synced = Strings.cloudFailed
            }
        }
    }
}
