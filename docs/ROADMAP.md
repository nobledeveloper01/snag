# Snag — Roadmap

`PHASE` holds the current number. `make phase` prints it and its gate.

Every phase has an **exit gate**: one sentence, machine-checkable where it can
be, that must be true before the next phase starts. A gate that cannot fail is
not a gate — so each one is broken on purpose, watched to fail, and put back.

Release gates are a different question and live in
[`RELEASE-GATES.md`](RELEASE-GATES.md). A phase gate blocks the next phase; a
release gate blocks v1.0.

**This project is iOS only, in Swift, by decision.** The portfolio's rule is
one codebase for both platforms; Snag is the second recorded exception, and
[ADR-0001](adr/0001-snag-is-native-and-ios-only.md) says why. Nothing below
mentions Android because nothing below runs on it.

---

## Phase 0 — Foundation · *cleared 2026-09-13*

The Xcode project, built and tested from the command line. The pure-Swift
domain as a package with no platform imports: a report, its rooms, its items,
the three tiers a number can come from, and the **canonical encoding** — the
one byte-exact serialisation of a report that is what gets hashed and signed.
The gates — documentation, domain purity, design, counts — and CI that runs
them on push. The splash.

**Exit gate**. *The app builds and tests from the command line on a
simulator, and a report with two rooms and six items round-trips through the
canonical encoding byte-identically, with the encoding asserted stable against
a fixture that is checked in.*

The last clause is the one that matters. Every signature this app will ever
make is over that encoding. If it changes by one byte between versions, every
report ever signed becomes *altered*. The fixture is the promise.

## Phase 1 — The report · *cleared 2026-09-14*

The photographs tier, which works on every iPhone: rooms named, items
photographed and described, each photograph hashed the moment it is taken. The
PDF. The signed bundle — a key in the Secure Enclave, a signature over the
canonical encoding, the public key in the bundle. Opening a bundle in Snag and
having it say *unaltered since signing* or *altered*. Sharing, through the
share sheet.

**Exit gate**. *A two-room report with six photographed items becomes a PDF
and a signed bundle; the bundle opened in the app verifies as unaltered; and
changing one byte of it makes the app say so.*

The third clause is the gate being proved to fire. A verifier that has never
seen a tampered file is a verifier nobody knows the behaviour of.

**Reached 2026-09-14** on the simulator: `SealTests` walks two rooms and six
fixture photographs to a seal, the sealed screen verifies its own bundle, a
relaunch with `-tamper` flips one byte and the screen says *Altered*, and the
same bundle opened through the document path says it again. What the gate
does not cover is a real camera, which is R1's kind of wait.

### The thirty, part one — the walk and the paper

Eighteen of the thirty features of [ADR-0004](adr/0004-thirty-things-and-the-line-each-does-not-cross.md),
in the order they are built. Each is proved on the simulator under the audit
before the next starts.

1. **Room templates.** Self-contain, one-bed, two-bed, three-bed, duplex: one
   tap and the rooms are named before the walk starts.
2. **Per-room prompts.** The things a Lagos flat has and a tenant forgets —
   the meter, the water heater, the AC, the burglary bars, the sockets, the
   flush, the nets — as one-tap captions on the shutter.
3. **Meter readings as items.** The prepaid meter and the water meter,
   photographed, the number in the caption, a digit keyboard offered.
4. **Keys.** How many, photographed on the table.
5. **Edit and delete before the seal.** Captions edited, items removed, rooms
   renamed and reordered. Nothing after.
6. **The same photograph twice is noticed.** Equal hashes, one item.
7. **Too dark, too blurred.** Said at capture, with the torch offered.
8. **The torch.** The design floor is a flat with the power off.
9. **Nothing but the picture.** EXIF and location stripped before the hash;
   the bundle carries no GPS.
10. **A draft survives a kill.** The walk resumes in the room it was in.
11. **The seal you can feel.** Haptics at capture and at seal; Reduce Motion
    honoured.
12. **The cover.** First photograph to last, minutes walked, a table of
    rooms with their snags and tiers.
13. **The PDF set in Inter**, as `DESIGN.md` has said since Phase 0, with a
    page number and the address and id on every page.
14. **The contact sheet.** Every photograph, small, with its hash prefix, so
    paper can be matched to the bundle.
15. **The QR on the cover.** Id and key fingerprint; *Check a paper copy*
    scans it against the bundles on this phone.
16. **One file.** `<id>.snag.zip`, because WhatsApp does not carry a folder;
    the verifier opens both.
17. **The share message carries the id** and how to check it.
18. **A second verifier, in Python**, written from `BUNDLE-FORMAT.md` alone
    and run in CI against a synthetic bundle — the proof that the format
    document is enough.

## Phase 2 — Measured · **current**

The ARKit tier: floor dimensions and area for each room, on any iPhone with an
A12 or later, measured by the tenant tapping corners. Every number in the
report carries its tier — *photographed*, *measured*, *scanned* — and the PDF
says so beside each one.

**Exit gate**. *A room's floor area measured with ARKit is within five per
cent of a tape measure, and the report names the tier beside every number.*

ARKit does not run in a simulator, so this gate needs a handset and stays open
until one has been watched — R1 in the release ledger.

**Built 2026-09-14, short of the sensor.** `Floor` in the domain turns corners
into width, length and area at the centimetre, with the tier, and a room takes
a measurement but never a lower tier over a higher one — property-tested.
`MeasureView` runs ARKit plane detection and raycasts each tap onto the floor
on a phone; on the simulator the same screen takes the fixture room's four
uneven taps. `TierTests` walks it to a seal. What remains is the sentence
above: a tape measure, a real room, five per cent.

## Phase 3 — Scanned

The RoomPlan tier, on iPhones with LiDAR: the tenant walks the flat and gets a
floor plan. The plan goes in the PDF. Doors, windows and openings are named
from the scan so a snag can be placed on the plan.

**Exit gate**. *A RoomPlan scan of a real flat produces a floor plan in the
PDF, the plan's area agrees with the ARKit tier within five per cent, and a
phone without LiDAR gets the Phase 2 report with no missing feature named.*

Needs a LiDAR handset — R2. The last clause is the honest version of a Pro
feature: a phone that cannot scan is told nothing is missing, because for that
tenant nothing is.

**Built 2026-09-14, short of the sensor.** `ScanView` runs RoomPlan's own
capture on a LiDAR phone and, when the room closes, projects the floor
polygon, the walls, the doors and the windows onto the floor plane as a
`ScannedFloor`; the simulator gets the fixture room. `PlanRenderer` draws the
plan — walls, openings, two dimensions, a metre bar — as a JPEG that goes into
the bundle by its hash as `planHash`, which both verifiers check; the PDF
draws it on the room's page. A scan outranks a measurement and a tap cannot
overwrite a scan. The last clause of the gate is already true: a phone with
neither sensor sees no button, and its report is complete.

## Phase 4 — Handover, and v1.0

The other party. A counter-signature drawn on the tenant's phone, with a name
and a phone number, into the same bundle. Move-out: the same walk, the move-in
photograph beside the new one, and a list of what changed. The report's
language reviewed by somebody who has argued a Lagos tenancy case, so that no
sentence in it claims more than it can. English and Pidgin.

**Exit gate**. *A tenant who moved in with a Snag report moves out with a
comparison, a landlord or agent has signed one on somebody else's phone, and a
lawyer has read the PDF and not asked for a change.*

### The thirty, part two — the handover

*Built 2026-09-14, ahead of this phase, because none of the six needs a
handset and Phases 2 and 3 do. The phase's exit gate — a real handover
watched, a lawyer's reading — is untouched by that and still waits.*

19. **The counter-signature, drawn.** Name, phone, a signature on glass,
    sealed as the second layer the format already has; a signature page in
    the PDF.
20. **Move-out linked to move-in.** A new report at an address with a sealed
    move-in offers the link; the id goes in the field the encoding has.
21. **Shoot the same view.** On a move-out walk the move-in photograph of
    that room sits beside the shutter.
22. **The diff page.** Same, changed, added, missing, per room, in the
    move-out PDF, from `Compare.diff`.
23. **Compare two bundles.** Any two for one address, on any phone.
24. **Walk out with Snag.** At move-in, a calendar entry on the tenancy's
    end date, in the tenant's own calendar.

**v1.0 ships to the App Store.** Every gate in
[`RELEASE-GATES.md`](RELEASE-GATES.md) is true, and somebody has watched each
one be true.

## Phase 5 — Depth · *v1.1*

An agent with five flats: several reports, searchable, each one still its own
signed bundle. Hausa, Yoruba and Igbo. iCloud sync between the tenant's own
devices, and only theirs — still no server. A report imported from a
photograph-only tier and upgraded with a scan later, both signatures kept.

**Exit gate**. *Five reports on one phone, one of them upgraded from
photographed to scanned with both signatures verifying, and the app in five
languages.*

**Built 2026-09-14, short of the readers.** The four languages, chosen in
the app and gated for completeness and for overclaiming, with the English
kept above the translation on the PDF; the amendment layer, a second
signature beside the first that may add numbers and plans and nothing else,
checked by both verifiers; and the tenant's own iCloud, opt-in, verified on
the way down, proved with a store in memory. [ADR-0005](adr/0005-v1-1-five-languages-an-amendment-layer-and-the-tenants-own-icloud.md).
What the gate still waits for: four native speakers (R5) and a signed-in
phone for CloudKit (with R1's handset).

### The thirty, part three — the agent with five flats

*Built 2026-09-14, ahead of this phase.*

25. **Find a report.** Search by address, sort by date, drafts and sealed apart.
26. **The app lock.** Face ID or the passcode to open Snag; off by default.
27. **Seal it before the boxes are in.** One local notification for a draft
    older than a day.
28. **Back up and restore.** Every sealed bundle to one zip in Files and
    back, each verified on the way in.
29. **Start a report from Siri**, Shortcuts, or a Home Screen quick action.
30. **The walk on the Lock Screen.** A Live Activity: address, rooms,
    minutes.
