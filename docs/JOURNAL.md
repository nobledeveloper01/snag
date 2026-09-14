# Journal

What we built, what we decided, and what surprised us. The surprises are the
point — everything else is in the commit log.

---

## 2026-09-12 — Why this one is native, and why the report is not proof

The second exception to the portfolio's one-codebase rule, and the first
thing written was the ADR making its own case rather than borrowing Tender's.
Tender is native because its user lives in the accessibility layer. Snag is
native because its two distinguishing tiers — RoomPlan and ARKit measurement
— exist only as native iOS frameworks, one of them only on Pro hardware, and
the signature that makes the report worth anything is a key in the Secure
Enclave. A cross-platform Snag would be the photographs tier alone.

### What surprised us

**The obvious sentence is a lie.** *"This proves the tile was cracked when I
moved in."* A Secure Enclave signature proves the bytes have not changed since
signing. It proves nothing about when, because the timestamp inside those
bytes came from a clock the tenant can set, and there is no server. The fixes
— a server timestamp, a notary, an anchor — are each a different product with
an account and a company holding evidence about people's homes. ADR-0003 says
*evidence, not proof*, and the PDF says it on its own last page so the tenant
is not surprised by it in the argument.

**The domain has to own the bytes.** The first draft had the report signed
over `JSONEncoder` output. `JSONEncoder`'s key order has changed between OS
versions before. A report signed on one iOS and opened on the next would
verify as *altered* with nobody having done anything. So the canonical
encoding is hand-written, length-prefixed, field-ordered, in a package that
imports nothing, and asserted byte-for-byte against a checked-in fixture. That
fixture is Phase 0's exit gate, ahead of any screen.

**The counter-signature is worth more than the cryptography.** A report the
landlord signed is evidence the landlord has to explain away. A report only
the tenant signed is evidence the tenant made. Phase 4 is about the other
party's name, and R3 is about watching it get there.

**Two of five phases need a handset, and the ledger says so on day one.**
RoomPlan and ARKit do not run in a simulator. Better to write R1 and R2 now
than to discover them at the end, as Harvest did with Android.

## 2026-09-13 — Phase 0: the bytes, fixed

The domain first: a report, its rooms and items, the three tiers, the
counter-signature, and the canonical encoding — hand-written, length-
prefixed, field-ordered, no floats, no maps, no encoder. Twelve tests in
two milliseconds: round trip for two hundred generated reports, every
truncation caught, trailing bytes refused, distinct reports never sharing
bytes, the move-out diff total. Then the fixture: a two-room, six-item
report encoded once and checked in, 554 bytes, with a test that refuses to
overwrite it. A one-byte change to the encoder fails it with *"every sealed
report in the world would read as altered"*, which is the sentence the
fixture exists to make true.

Then the app: the project file carried over from Tender, the palette from
DESIGN.md, Inter bundled, the mark, the splash, the empty state, a new
report, and a walk that adds rooms with their tier chips. Eight app tests
including the audit on five screens at two sizes; nine gates, each broken on
purpose. `make ci` exit 0, and the repo is public.

### What surprised us

**`Dimension` is Foundation's.** The domain compiled alone and failed the
moment a test imported Foundation. `Extent` now, and a note in the model
about why.

**The audit found four things on the first run, again.** The empty state
was not in a scroll view and clipped at large sizes; the address field was
single-line; *Cancel* was a toolbar item, which Tender had already taught;
and a vertical `TextField`'s inner view sizes to its content whatever frame
it is given, so the audit measured a 20 pt target — a `TextEditor` owns its
frame. Four screens, four defects, before any person looked.

**A mutation that does not apply proves nothing.** The counts gate "did not
fire" on a removed tier because the `sed` was one space off and removed
nothing. Applied properly, it fired on two documents. Check the mutation
landed before reading the result.

## 2026-09-14 — Phase 1: the first seal

The sealer and the verifier first, as units: a key in the Secure Enclave
where the simulator pretends to have one and in the Keychain where it does
not, a DER signature over SHA-256 of the canonical bytes, a bundle on disk,
and a verifier that was handed every file with every byte flipped in turn —
over fifteen hundred bundles, every one *altered*. Then the screens: the
shutter fed by three fixture photographs on the simulator, the item sheet,
the review, the seal, the sealed screen that runs the verifier over its own
files every time it appears, the PDF, and the document path so a bundle
from another phone opens to the same verdict. `SealTests` walks two rooms
and six photographs to a seal — the shape the exit gate names — relaunches
with `-tamper`, and reads *Altered* off the screen. Sixteen app tests, the
domain's twelve, `make ci` green.

Then the thirty. ADR-0004, phased: eighteen for the walk and the paper,
six for the handover, six for the agent. The encoding is the constraint
none of Tender's twenty had: nothing may add a field, so everything is an
item, a caption, a room, or a layer beside the report.

### What surprised us

**An unsigned app has no Keychain.** `CODE_SIGNING_ALLOWED=NO` had been
carried over from Tender, which stores nothing. The Keychain answered
-34018 to an app with no application identifier. The simulator signs ad
hoc on its own; the flag is gone.

**The audit reads a row under a pinned button as visible.** The sealed
screen listed every room and item under a two-button inset, and the row
nearest the inset failed the Dynamic Type check: at the larger size it
slid under the buttons and its measured frame stopped growing. Three
attempts at restructuring the row did nothing, because the row was never
the problem. The detail moved behind a link to a screen with no pinned
action, where a long report scrolls to its end — which is also where a
reader wants it.

**A store that lists only bundles that verify hides the tampered one.** The
opened-bundle test found it: after `-tamper` the report vanished from the
list instead of being shown as altered. A bundle that has gone bad on disk
is listed if it decodes, and the screen says what the verifier says.

**`firstMatch` on a label that two screens share taps the wrong one.** With
*Review* on the walk, the sheet's *Add a room* was no longer first. An
identifier on the sheet's button; the label stays for the person.

## 2026-09-14, later — the thirty, part one

Eighteen features between two and four in the morning, in three batches
with one simulator run each where it could be managed: the walk
(templates, prompts, meter and keys, edit and delete, the duplicate rule,
resume, haptics), the capture (the judge, the torch, the strip), the paper
(the cover, Inter, page numbers, the contact sheet, the QR, one file, the
share message, the Python verifier). Domain first for the parts that are
data — templates, the duplicate rule, the timeline, the room labels — with
sixteen tests; the app wired; the audit over every new screen.

### What surprised us

**The app was not in Inter.** `DESIGN.md` had said "Inter, bundled" since
Phase 0, `Type.swift` said `.custom("Inter")`, and `UIFont(name: "Inter")`
returned nil: the variable font's PostScript name is `InterVariable` and
SwiftUI falls back to the system face without a word. Found by the PDF
test asking for the font's family. `TypeTests` now asks UIFont directly,
and `design-check` refuses any font that is not relative to a text style.

**The audit's Dynamic Type check is not a Dynamic Type check.** Three
rows in a row on the paper-check screen were called "partially
unsupported" — the verdict, then the Check button, then the hint — as the
screen was rearranged. Screenshotted at L and at AX5, every one of them
scales. The check measures a row's growth in place, and a row near the
bottom of a list is clipped as it grows. The audit no longer asks it;
the source is checked for fixed sizes instead, and `.textClipped` at the
largest size says what a person would see.

**A fixture that repeats is a duplicate.** The photo source was made per
room, its shot counter restarted, and the bedroom's first photograph was
the kitchen's — refused, correctly, by the rule written an hour earlier.
One source for the app now; the rule stays.

**A per-word `capitalized` is not sentence case.** "Two Bedroom", "Boys'
Quarters". A four-line `sentenceCased`.

**The Python verifier agreed first time.** Forty lines of P-256 from the
constants, a DER parser, the decoder from the format document, and the
app's own sealed bundle read *unaltered* on the first run. The gate hands
it five tampers every run so that agreement is never the only evidence.
