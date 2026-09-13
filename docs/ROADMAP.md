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

## Phase 0 — Foundation · **current**

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

## Phase 1 — The report

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

## Phase 2 — Measured

The ARKit tier: floor dimensions and area for each room, on any iPhone with an
A12 or later, measured by the tenant tapping corners. Every number in the
report carries its tier — *photographed*, *measured*, *scanned* — and the PDF
says so beside each one.

**Exit gate**. *A room's floor area measured with ARKit is within five per
cent of a tape measure, and the report names the tier beside every number.*

ARKit does not run in a simulator, so this gate needs a handset and stays open
until one has been watched — R1 in the release ledger.

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

## Phase 4 — Handover, and v1.0

The other party. A counter-signature drawn on the tenant's phone, with a name
and a phone number, into the same bundle. Move-out: the same walk, the move-in
photograph beside the new one, and a list of what changed. The report's
language reviewed by somebody who has argued a Lagos tenancy case, so that no
sentence in it claims more than it can. English and Pidgin.

**Exit gate**. *A tenant who moved in with a Snag report moves out with a
comparison, a landlord or agent has signed one on somebody else's phone, and a
lawyer has read the PDF and not asked for a change.*

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
