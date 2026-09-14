// Measured or scanned after the seal: a photographed report gets its
// numbers later, on a phone that has the sensor, without touching a
// photograph, a caption or the original signature. Each room can be
// measured or scanned; the amended report is sealed as its own layer.
import SwiftUI
import SnagDomain

struct AmendView: View {
    @Bindable var store: ReportStore
    let sealed: ReportStore.Sealed
    let done: (ReportStore.Sealed) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var report: Report
    @State private var plans: [([UInt8], URL)] = []
    @State private var measuring: Int?
    @State private var scanning: Int?
    @State private var failure: String?

    init(store: ReportStore, sealed: ReportStore.Sealed, done: @escaping (ReportStore.Sealed) -> Void) {
        self.store = store; self.sealed = sealed; self.done = done
        _report = State(initialValue: sealed.report)
    }

    private var changed: Bool { report != sealed.report }

    var body: some View {
        let palette = Palette.current(scheme)
        let labels = report.roomLabels
        NavigationStack {
            List {
                Section {
                    Text(Strings.amendHint).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                }
                ForEach(Array(report.rooms.enumerated()), id: \.offset) { i, room in
                    Section {
                        if let w = room.width, let l = room.length, let a = room.area {
                            Text(Dimensions.line(w, l, a)).font(Type.bodyFont()).foregroundStyle(palette.textPrimary).frame(minHeight: Target.standard)
                        } else {
                            Text(Strings.noMeasurement).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary).frame(minHeight: Target.standard)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Gap.s) {
                                if Sensors.canMeasure || Sensors.fixtures {
                                    Button(Strings.measureRoom) { measuring = i }.buttonStyle(Chip(palette: palette)).disabled(room.tier == .scanned)
                                        .accessibilityIdentifier("measure-\(i)")
                                }
                                if Sensors.canScan || Sensors.fixtures {
                                    Button(Strings.scanRoom) { scanning = i }.buttonStyle(Chip(palette: palette))
                                        .accessibilityIdentifier("scan-\(i)")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(labels[i].sentenceCased).font(Type.secondaryFont()).foregroundStyle(palette.textSecondary)
                            Spacer()
                            TierChip(tier: room.tier, palette: palette)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if let failure {
                    Section { Text(failure).font(Type.secondaryFont()).foregroundStyle(palette.snag) }
                }
            }
            .scrollContentBackground(.hidden)
            .listRoom()
            .pinned {
                VStack(spacing: Gap.s) {
                    Button(Strings.sealAmendment) { seal() }
                        .buttonStyle(Primary(palette: palette))
                        .disabled(!changed)
                        .accessibilityIdentifier("sealAmendment")
                    Button(Strings.cancel) { dismiss() }.buttonStyle(Secondary(palette: palette))
                }
                .padding(Gap.l)
            }
            .navigationTitle(Strings.amend)
        }
        .tint(palette.accent)
        .sheet(item: $measuring) { i in
            MeasureView { corners in _ = report.rooms[i].measure(corners, tier: .measured) }
        }
        .sheet(item: $scanning) { i in
            ScanView { floor in
                guard report.rooms[i].measure(floor.corners, tier: .scanned),
                      let jpeg = PlanRenderer.jpeg(floor, label: labels[i].sentenceCased) else { return }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("plan-\(UUID().uuidString).jpg")
                try? jpeg.write(to: url)
                let hash = SnagBundle.sha256(jpeg)
                plans.append((hash, url))
                report.rooms[i].planHash = hash
            }
        }
    }

    private func seal() {
        do {
            let updated = try store.amend(sealed, with: report, plans: plans, sealer: try Sealer(), now: Clock.now())
            Haptics.sealed()
            done(updated)
            dismiss()
        } catch {
            failure = Strings.sealFailed
        }
    }
}
