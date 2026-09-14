# Release gates

Everything here must be true before v1.0 ships. None of it blocks the next
phase — a phase gate and a release gate are different questions.

**This list is the commitment.** "We will do it before launch" is a sentiment;
this is a ledger. If it grows past what one screen holds, the product is being
built past the point anybody can honestly ship it.

How each is cleared, step by step, is [`HANDSET-DAY.md`](HANDSET-DAY.md).

## Blocks v1.0

| # | Gate | Waiting on | Expected to clear in |
|---|---|---|---|
| R1 | **The ARKit tier on a physical iPhone.** Built 2026-09-14 and proved on the simulator with a fixture room; a simulator has no camera and no motion sensors, so the measured tier has never measured anything real. Within five per cent of a tape measure, in a real room, in the light a Lagos flat actually has | A handset with an A12 or later | Phase 2 |
| R2 | **The RoomPlan tier on a LiDAR iPhone.** Built 2026-09-14 — the scan, the plan in the bundle and the PDF — and proved with a fixture room; the headline feature has never run on a sensor. A scan of a real flat — with a generator in the corner, a wardrobe against the wall and a window the sun comes through — producing a plan that agrees with the tape | A Pro iPhone, 12 Pro or later | Phase 3 |
| R3 | **A real handover, watched.** A tenant and a landlord or agent, on move-in day, one phone, one report, two signatures. Every flow in this app was designed by somebody who has not stood in that doorway with those two people | A tenant moving in, and the other party, in Nigeria | Phase 4 |
| R5 | **Each translation read by a native speaker.** Naijá, Yorùbá, Hausa and Igbo are drafts by the developer — 203 strings each, gated for completeness by `make l10n-check` and for overclaiming by `make copy-check`, but never yet read by anybody who grew up in the language. The PDF's last page keeps the English above the translation for that reason. Four readers, an hour each | A native speaker of each, in Nigeria | v1.1 |
| R4 | **The report's language reviewed by somebody who has argued a tenancy case.** The PDF is the thing that gets put on a table. Every sentence in it — what a tier means, what a signature means, what the report does and does not prove — is written by a developer reading the Lagos Tenancy Law, which is a starting point and not a result. The reviewer is not asked whether it is admissible; they are asked whether it overclaims | A Lagos tenancy lawyer, for an hour | Phase 4 |

## Cleared

| # | Gate | How |
|---|---|---|

## How a gate leaves this list

By being true, and by somebody having watched it be true. Not by being
reworded, and not by being moved to a later phase.
