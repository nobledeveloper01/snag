# Feature backlog

Things worth building that are not in the current phase. Each one names why it
is not being built yet, because "later" without a reason is how a backlog turns
into a graveyard.

| | Why not now |
|---|---|
| Hausa, Yoruba and Igbo | **Built 2026-09-14**, with Naijá, as drafts — R5 is the native speakers. Was: v1.1. The primary persona is an iPhone-owning tenant in Lagos, Abuja or Port Harcourt, and English and Pidgin cover that person. The other three arrive with the strings already in one enum, so it is translation and not engineering. |
| An agent with several flats | **Built, and this row was stale.** The reports list holds every draft and every sealed report on the phone, drafts above and sealed below, and grows a search field the moment there are more than two — *an agent with five flats finds one by its address* is the comment beside it. Was: v1.1, on the argument that a list screen before a second report is furniture; the second report arrived with search and compare on 2026-09-14, and the row was not updated. Noticed 2026-09-17 in an audit for remaining code. |
| Upgrading a photographed report to a scanned one later | **Built 2026-09-14** as the amendment layer, ADR-0005. Was: v1.1. Needs two signatures over two encodings in one bundle, and the sealing model should be proved on one signature first. |
| iCloud sync between the tenant's own devices | **Built 2026-09-14**, opt-in, ADR-0005; CloudKit itself waits for a signed-in phone. Was: v1.1, and only with CloudKit's private database — still no server of ours. Deferred because a report lives on the phone that made it, and losing that phone is a rarer problem than the ones ahead of it. |
| A server timestamp, or a notary | **Not scheduled**, and the reason is [ADR-0003](adr/0003-the-report-is-evidence-not-proof.md). Listed so the request has somewhere to land. |
| A deduction calculator | **Never.** The app records the condition of a room; what that is worth is between the parties, and the moment the app says a number it is giving legal advice about money. |
| A fourth tier, measured against a reference object in the photograph | **Refused** by [ADR-0004](adr/0004-thirty-things-and-the-line-each-does-not-cross.md). A number that is neither photographed, measured nor scanned is a number with no tier, and the tier beside every number is a rule. |
| Annotating a photograph — a circle round the crack | **Refused.** The annotated image would become the evidence and the original would not be in the bundle. The caption says where the crack is. |
| Who was present, as a field in the report | **Refused.** A field is a change to the encoding, and the encoding never changes. Presence is the counter-signature, or it is nothing. |
| Placing a snag on the floor plan | Phase 3's roadmap text promised it and it is not built: it needs a scanned room *and* a tap on the plan, which is a second coordinate in the item — a field the encoding does not have. Version 2 of the encoding, with an ADR, when a scanned report has been watched on a real phone. |
| Landlord-side app | Not scheduled. The landlord signs on the tenant's phone, which is the point: one phone, one report, no account. A landlord who wants their own copy has the PDF and the bundle. |

## Built, and why

The thirty of [ADR-0004](adr/0004-thirty-things-and-the-line-each-does-not-cross.md)
land here as each is proved. The list of thirty and the phase that builds each
is in [`ROADMAP.md`](ROADMAP.md).

| | What it is for |
|---|---|
| Room templates | Self-contain to duplex: the rooms are named before the walk starts. A tenant in a doorway makes one decision, not seven. Domain: `RoomTemplate`. |
| Per-room prompts | The meter, the water heater, the burglary bars, the flush: what a Lagos flat has and a tenant forgets. One tap photographs with the caption started. `Prompts.swift`, read by the copy gate. |
| Meter readings as items | The prepaid and water meters, photographed, the number in the caption in the tenant's words — never a number the app made, never money. |
| Keys | How many were handed over, counted on the sheet and photographed on the table. |
| Edit and delete before the seal | A wrong photograph is not a wrong report. Captions edited, items removed, rooms renamed, reordered and removed. After the seal, nothing. |
| The same photograph twice is noticed | Equal hashes, one item, refused before the bytes are written. Domain: `Report.contains(photoHash:)`. Proved with `-repeatFixture`. |
| Too dark, too blurred | A 96-pixel grey copy, mean luminance and a Laplacian's variance, judged before the hash; the word under the picture and the torch offered. Thresholds set by fixtures. |
| The torch | The design floor is a flat with the power off. Beside the shutter, on phones that have one. |
| Nothing but the picture | Re-encoded through a renderer before the hash: no EXIF, no GPS, no maker note. Proved against a JPEG tagged with a Lagos latitude. |
| A draft survives a kill | The walk resumes in the room it was in. Proved by terminating the app mid-walk. |
| The seal you can feel | A tap at capture, a thud at the seal, a nudge at a refusal. |
| The cover | Minutes walked from first photograph to last, and a table of rooms with their snags and tiers. Domain: `Report.walked`, `minutesWalked`, `roomLabels`. |
| The PDF set in Inter, numbered | As `DESIGN.md` said since Phase 0 — and the font name was wrong until `TypeTests` asked UIFont; the app had been in the system face without a word. Every page carries the address, the id and *page n of N*. |
| The contact sheet | Every photograph, small, with twelve characters of its hash, so a print can be matched to the file it came from. |
| The QR on the cover, and *Check a paper copy* | The id and eight bytes of the key's hash; the camera or a typed line matches paper to a bundle on this phone. Never says the paper is true. |
| One file | `<id>.snagz`, a stored zip written by forty lines of our own, because WhatsApp does not carry a folder. The reader also takes deflated entries, proved against a zip `zip -X` made. |
| The share message carries the id | The words travel with the bytes: what it is, how to check it, which one it is. |
| The counter-signature, drawn | Name, phone, a signature on glass, rendered to a picture that is hashed and named in the counter-signature layer the format already had — `signature.jpg` beside it, bound the way a photograph is. Both verifiers check it. A signature page in the PDF. |
| Move-out linked to move-in | A new move-out offers every sealed move-in on the phone; the link goes in `movedInReportId`, the field the encoding has, and the walk starts with the move-in's rooms in its order. |
| Shoot the same view | On a linked move-out, the move-in's photographs of the room sit beside the shutter, each a tap from its retake with the same caption. |
| The diff page | `Compare.diff` in the domain; *same, changed, new, not photographed this time* per room in the app and in the PDF. Never what a change costs. |
| Compare two bundles | An opened move-out is compared to the move-in this phone holds — on any phone that holds it — under the verdict. |
| Walk out with Snag | One all-day event in the tenant's own calendar on the day the tenancy ends, with write-only access. Proved on the simulator, permission prompt and all. |
| Find a report | A search row when there are more than two reports; by address; newest first; drafts and sealed apart. |
| The app lock | Face ID, Touch ID or the passcode, through the phone's own `LocalAuthentication`; off by default; disabled where the phone has no passcode. The simulator answers with a passcode sheet, which the test cancels and reads the honest failure. |
| Seal it before the boxes are in | One local notification a day after a draft is started, provisional so no prompt in the doorway; cancelled at the seal or the delete; off in Settings. |
| Back up and restore | Every sealed bundle in one `.snagbackup` zip to Files; on the way back each bundle is verified before it is kept, and one already here is refused. |
| Start a report from Siri | An App Intent with App Shortcuts phrases, the `snag://new` URL, and a Home Screen quick action, all ending in the same flag that opens the sheet. |
| The walk on the Lock Screen | A Live Activity from a widget extension — the first second target in the hand-written project — with the address, rooms, items, snags and minutes; started with the walk, ended at the seal. Proved as far as a simulator reaches: the state, and that the calls are harmless where activities are off. |
| A second verifier, in Python | `scripts/verify.py`, from `docs/BUNDLE-FORMAT.md` alone, P-256 included, no dependencies. `make verify-check` runs it against the app's own bundle and five tampers every time. The proof that the format document is enough. |
