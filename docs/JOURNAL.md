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

## 2026-09-14, before dawn — the thirty, parts two and three

Twelve more, from the handover and the agent's phone, built ahead of their
phases because none needs a handset and the two phases before them do. The
counter-signature first, and it changed the format: the drawn signature is
a picture, and a picture in a bundle is bound by its hash, so `signature.jpg`
sits beside the layer and both verifiers check it — the fixture was
re-sealed and the gate gained a tamper. Then the move-out: linked to its
move-in through the field the encoding always had, starting with the
move-in's rooms, the old photographs beside the shutter, the diff on the
sealed screen and on a page of the PDF, and the same diff for a bundle
opened on another phone. The calendar entry, the search row, the lock, the
nudge, the backup, Siri, and the Live Activity, which needed the first
second target in the hand-written project file — a widget extension and a
folder shared by two targets, which the synchronised-group format allows.

Thirty-seven app tests, twenty domain tests, `make ci` green.

### What surprised us

**The simulator has a passcode.** Device-owner authentication does not
fail on it; it puts up a passcode sheet of its own. The test cancels the
sheet and reads *Not unlocked. Try again.* — which is the honest screen a
tenant with a locked app and a forgotten passcode would see.

**A signature under a keyboard is a scroll.** The pad sat below the phone
field, the keyboard covered it, and the press-and-drag went to the
keyboard. A *Done* over the keyboard, which the tenant needs too.

**The audit reads a calendar grid as text it cannot reach.** The graphical
date picker is the system's; its day numbers were flagged. Compact.

**Two targets, one file name, one build.** The app's `WalkActivity.swift`
and the shared `WalkActivity.swift` produced the same intermediate and the
build refused. Renamed; a synchronised folder shared by two targets is
otherwise as simple as listing it under both.

**A test hook that writes a setting outlives the test.** `-lock` wrote
`pref.lock` to the simulator's defaults so the locked screen could be
looked at; the next launch without `-freshStore` was the unit-test host,
which came up behind the simulator's passcode sheet, and xcodebuild
reported "the test runner hung before establishing connection" — twice,
only under `make ci`, never under `make test-app`, because the order of
launches differed. `-lock` is now an in-memory override, and a test host
never locks. The simulator was erased to be sure.

## 2026-09-14, dawn — the pictures

`make screenshots`: a UI test walks the flow the README shows and attaches
a screen at each step; a script pulls them out of the result bundle and
shrinks them. Eleven frames, interleaved through the README under the
walk, the seal, and the paper.

### What surprised us

**The screenshot run found a hidden bundle.** The two-bedroom template
leaves the balcony empty, so the tampering hook's flipped last byte landed
on the room's item count instead of a timestamp, the report no longer
decoded, and the store — which listed only bundles it could decode — made
it vanish. A bundle that has gone bad is now listed under *Cannot be read*
and opens to *Altered*; the paper check says the same. The second time a
tampered bundle has tried to disappear, and the second rule against it.

**Two buttons that say Done.** The keyboard's new Done and the sheet's
pinned Done shared a label; a test tapped the wrong one on the CI runner
and the right one here. *Hide keyboard* now, which is also what it does.

**The CI runner asks for calendar permission and nobody answers.** The
interruption monitor fires locally and not there; the test now also looks
for SpringBoard's button by name. The result bundle is kept as an artifact
on failure, which is how this was read at all.

**Launched into a simulator still booting.** The hang came back after the
lock was ruled out — one run in three, only from a cold simulator, and the
host app never crashed: xcodebuild boots the simulator and launches the
test host into it at once, and XCTest gives up on the connection before
the phone is up. `make test-app` now boots and waits for `bootstatus`
first, which is what the CI workflow had always done, and where it never
hung.

## 2026-09-14, morning — the hand test, and the hang found

The app driven by hand on the demo simulator, end to end: template, kitchen,
a prompt, two photographs, review, seal, counter-signature on glass, the
nine-page PDF read in Preview, a move-out linked to the move-in with the
old views beside the shutter and the diff on the sealed screen, the
settings. Two things a person sees that a test did not: the review screen
said *Living Room* where every other screen says *Living room*, and *Walk
the flat* put the tenant back on the list instead of in the walk. Both
fixed; the tests that expected the old landing were rewritten.

### What surprised us

**The hang was our own scene delegate.** "The test runner hung before
establishing connection" — one run in three, only the unit-test host,
never crashing, its own log going quiet with the window up and no XCTest
line ever written. The quick action had been wired through
`UIApplicationDelegateAdaptor` with a `configurationForConnecting` that
named a scene delegate class of ours, and that replaced the one SwiftUI
uses to host the app. Six cold launches without it: 25, 19, 18, 26, 21,
22 seconds, none hung. The quick action goes through the app delegate's
own `performActionFor` now, which UIKit calls when the scene delegate does
not take it. The boot-first change stays; it was right for the runner and
wrong about the cause.

## 2026-09-14, mid-morning — the sensors' tiers, without the sensors

"Build it, we will test the hardware later." Phases 2 and 3, then, as far
as a simulator reaches. The domain first: `Floor` — the shoelace area, the
sides of the tightest rectangle along the longest edge so a slanted tap
measures the same as a square one, the centimetre rounding, and a room
that takes a measurement but never a lower tier over a higher one. Twenty-
one domain tests. Then ARKit: plane detection and a raycast per tap, the
corner's x and z on the floor; and RoomPlan: the captured room's floor
polygon and the bottom edges of its walls, doors and windows projected
onto the floor plane. Both end in the same `ScannedFloor`, which is what
the plan renderer draws and what the fixture provides on the simulator,
so the plan, the bundle, both verifiers and the PDF are exercised here.
The viewfinder too, since a phone's shutter had been firing blind.

### What surprised us

**The domain has no trigonometry.** No Foundation means no `sin`; the test
that turns the rectangle brings a twelve-term series of its own. Six lines,
and the domain stays pure.

**Phase 3 promised a thing the encoding cannot hold.** "A snag placed on
the plan" needs a coordinate on the item, and the item has no such field.
It goes to the backlog with its reason — version 2, with an ADR, after a
real scan has been watched — rather than into a caption where a number
would pretend to be a word.

**`16 == 16.0` is not true in a test macro.** `#expect(area == 12 + 4)`
compared a Double? with an Int and failed with both sides printing 16.

## 2026-09-14, midday — v1.1, and the hang found for real

"Let's do v1.1 too." Five languages first: every string routed through one
lookup keyed by its English, four tables of 202, a gate that fails on a
missing one and the copy gate reading every table — which caught "burglary
proof" in the Pidgin, the Lagos word, and was right to. Then the amendment
layer, designed so the first seal is never touched: a second signed file
beside it that may add numbers and plans and nothing else, and both
verifiers refusing a reworded caption or a report moved under another id.
Then iCloud, written against a protocol and proved with two phones in
memory before a line of CloudKit was called.

### What surprised us

**The hang has now had three explanations, and all three were wrong.**
A cold simulator, then our scene delegate, then a rebuild inside the same
`xcodebuild test` — each held for six clean runs and then the host hung
again with none of them present. What is true: it is the hosted unit
bundle only, one launch in three, the app itself never crashing, the UI
runner never hanging. The Makefile now retries the unit bundle up to
three times and says so; the three wrong explanations stay in this journal
because each one looked like proof for a day.

**A PDF loses its glyphs in extraction.** The "×" between two dimensions
and the tone marks on Yorùbá both came back from PDFKit's text as
something else. The tests read the words around them now.

**A translation can fail the copy gate.** Which is the reason the copy
gate reads the translations.

## 2026-09-15 — the README in Grid's shape

The README is Grid's twelve sections now — the problem, how it works, the
app, each layer, quick start, correctness notes, the pipeline, data handling,
development, layout, status, licensing — because the user asked for that
shape across the portfolio. The counts gate held the numbers sentence to a
form: a figure and its middle dot have to sit on one line, or the regex that
guards the figure reads it as gone. The repository also had no licence file;
it has the portfolio's pair now — BSL for the app, Apache-2.0 for
`SnagDomain` — with the grant written for tenancies.

**Two UI tests failed on a documentation-only push, and passed on re-run.**
`testAReportIsFoundByItsAddress` and `testTheSettingsAreReadAndTheLockShowsItsScreen`,
both with three-second waits and one with SpringBoard's passcode sheet in it.
Nothing in the commit touched code. The runner is the third machine these
tests have flaked on for timing, and the honest fix is not a longer wait
but the retry the unit bundle already has — noted here so the next failure
on a README push is read as the runner before it is read as the app.
