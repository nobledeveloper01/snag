# Changelog

All notable changes to Snag, in the style of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by
[semver](https://semver.org/spec/v2.0.0.html).

Entries say *why*, not just what.

## [Unreleased]

### Added

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
