# Changelog

All notable changes to Snag, in the style of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by
[semver](https://semver.org/spec/v2.0.0.html).

Entries say *why*, not just what.

## [Unreleased]

### Added

- **v1.1, short of the readers.** Five languages — English, Naijá, Yorùbá,
  Hausa, Igbo — chosen in Settings and not by the phone, 203 strings each,
  `make l10n-check` failing on any one missing and `make copy-check` reading
  every translation; the PDF keeps the English above the translation. The
  amendment layer: a sealed report measured or scanned later as a second
  signed layer beside the first, numbers and plans only, both verifiers
  refusing anything else; `Measure or scan later` on the sealed screen. The
  tenant's own iCloud: private CloudKit, opt-in, one file per bundle, each
  verified before it is kept, proved against a store in memory. ADR-0005.
  The release ledger gains R5, a native speaker per language.
- **Phases 2 and 3, short of the sensors.** The measured tier: `Floor` in
  the domain turns tapped corners into width, length and area at the
  centimetre with their tier, property-tested; `MeasureView` raycasts each
  tap onto ARKit's floor plane on a phone. The scanned tier: `ScanView`
  runs RoomPlan on a LiDAR phone and projects the floor, walls, doors and
  windows onto the floor plane; `PlanRenderer` draws the plan as a JPEG
  that goes into the bundle by its hash and onto the room's PDF page. A
  scan outranks a measurement; a tap cannot overwrite a scan; a phone with
  neither sensor sees no button. On the simulator a fixture room stands in
  for both sensors, and `TierTests` walks it to a seal. The exit gates — a
  tape measure in a real room — wait on handsets, R1 and R2.
- **The viewfinder.** On a phone the shutter opens a live preview with the
  torch beside it before a photograph is taken; the simulator's fixture
  path is unchanged.
- **Phase 1, the report.** Photographs hashed the moment they arrive and
  stored by hash; items with a caption and *snag* or *fine*; a review; a
  seal by a P-256 key in the Secure Enclave or, failing one, the Keychain;
  the bundle on disk as `docs/BUNDLE-FORMAT.md` describes; a sealed screen
  that verifies its own bundle every time it appears; the PDF, one room per
  page with the tier word beside every room and the last page saying what
  the report is; opening a `.snag` bundle from outside; sharing both. The
  verifier is proved against every flipped byte of every file in a unit test
  and against one flipped byte on a real screen in a UI test, because a
  verifier that has never seen a tampered file is one nobody knows the
  behaviour of.
- **The thirty, part one — the walk and the paper.** All eighteen of Phase
  1's features from ADR-0004, each under the audit on the simulator: room
  templates, per-room prompts, meter readings and keys as items, edit and
  delete before the seal, the duplicate-photograph rule, the dark-and-blur
  judge, the torch, EXIF and location stripped before the hash, the walk
  resuming after a kill, haptics, the cover with its timeline and table,
  the PDF set in Inter with page numbers, the contact sheet, the QR and
  *Check a paper copy*, the one-file `.snagz` bundle with its own zip
  reader and writer, the share message, and a second verifier in Python
  gated by `make verify-check` against the app's own sealed fixture.
- **The thirty, parts two and three — the handover and the agent.** Built
  ahead of their phases, because Phases 2 and 3 wait on handsets and none
  of these needs one: the counter-signature drawn on glass and bound into
  the bundle as `signature.jpg` (both verifiers check it; the fixture was
  re-sealed), the move-out linked to its move-in with the same views beside
  the shutter and a diff page in the app and the PDF, two bundles compared
  on any phone, the calendar entry for the day the tenancy ends, search by
  address, the app lock, the seal nudge, backup and restore, Siri and the
  quick action, and the walk as a Live Activity from a new widget extension.
- `design-check` now fails on any font that is not relative to a text
  style, and the UI tests no longer ask the audit about Dynamic Type, which
  it measured wrongly for rows near the bottom of a list.
- **ADR-0004, thirty things.** The plan for thirty more features, each
  checked against the seven rules, phased into the roadmap: eighteen for
  this phase, six for the handover, six for the agent with five flats.
- **Phase 0.** The domain as a package that imports nothing: the report
  model, the canonical encoding and its decoder, the move-out diff, and the
  checked-in fixture that fixes the encoding byte for byte. The app: a
  hand-written Xcode project, Inter bundled, the splash, the empty state,
  a new report, the walk adding rooms with their tier chips. Nine gates each
  proved to fire, CI on push, tests on a headless simulator named
  "Snag Tests".
- The documents: product statement, roadmap with an exit gate per phase, the
  release ledger, the design system, and three ADRs — why this project is
  native and iOS-only, why the domain imports nothing and owns the canonical
  encoding, and why the report is evidence and never proof.
