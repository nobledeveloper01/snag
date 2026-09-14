# ADR-0005 — v1.1: five languages, an amendment layer, and the tenant's own iCloud

**Status:** accepted
**Date:** 2026-09-14

## Context

Phase 5 was written as v1.1 before any code existed: an agent with five
flats, the four other languages, iCloud between the tenant's own devices,
and a photographed report upgraded to a scanned one later with both
signatures kept. The agent's features landed with the thirty. The other
three each threatened one of the rules in `CLAUDE.md`, and each needed a
decision before its code.

**Languages** threaten *evidence, never proof*: a translation can claim
what the English does not, and the copy gate reads English. They also
threaten the report's standing: a PDF in a language the reader's lawyer
does not read is a weaker document than one in English.

**Upgrading a sealed report** threatens the first rule: *the canonical
encoding never changes*. The obvious design — re-seal the report with the
new numbers — destroys the original signature, which is the thing the
tenant's landlord has already seen.

**iCloud** threatens *nothing is sent*. The product statement's sentence is
that no server of ours holds evidence about people's homes; Apple's, under
the tenant's own Apple ID, was allowed for v1.1 in the roadmap from the
first day, and this ADR is where the line is drawn precisely.

## Decision

**Languages are chosen in the app, not by the phone, and the English is
the report.** Every string is written once, in English, and looked up by
that English text in the chosen language. `make l10n-check` fails on any
string any language lacks; `make copy-check` reads every translation for
the words that would overclaim, in English and by loanword. The PDF's last
page keeps the English above the translation, because the English is what
was written and the translations are a developer's drafts — R5 in the
ledger is a native speaker of each reading it, and the picker says so.

**An amendment is a second signed layer, never a second seal.** The
original `report.bin` and `report.sig` are not touched. `amendment.bin` is
the original's id, a date and the whole amended report; `amendment.sig` is
the same key over it. A verifier that knows only version 1 still verifies
the original alone; one that knows the layer verifies both and shows the
amended numbers. The layer may change a room's numbers and plan and
nothing else — not a photograph, not a caption, not the date, not a tier
downward — and both verifiers refuse one that does. The encoding of the
report, and the fixture, are untouched.

**iCloud is the private CloudKit database, opt-in, one file per bundle,
verified on the way down.** The mirror is written against a protocol and
proved with a store in memory: two phones, a tampered file refused, a new
layer travelling up and down. CloudKit itself is imported in one folder,
`Snag/Cloud`, and `network-check` fails on it anywhere else. There is still
no server of ours.

## Consequences

**The ledger grows by one row**, R5, for the native speakers — the second
time a translation has joined R1's kind of wait rather than pretend to be
finished. R6, CloudKit on a signed-in phone, is folded into R1's handset
day rather than listed: it is the same phone.

**The bundle format gains its last optional layer.** `BUNDLE-FORMAT.md`
now has three: the seal, the counter-signature, the amendment. A fourth
would be the moment to ask whether version 2 of the encoding is due.

**"Place a snag on the floor plan" stays in the backlog.** It needs a
field on the item, which is the encoding, which this ADR did not touch.
