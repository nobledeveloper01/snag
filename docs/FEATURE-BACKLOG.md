# Feature backlog

Things worth building that are not in the current phase. Each one names why it
is not being built yet, because "later" without a reason is how a backlog turns
into a graveyard.

| | Why not now |
|---|---|
| Hausa, Yoruba and Igbo | v1.1. The primary persona is an iPhone-owning tenant in Lagos, Abuja or Port Harcourt, and English and Pidgin cover that person. The other three arrive with the strings already in one enum, so it is translation and not engineering. |
| An agent with several flats | v1.1. One tenant, one flat, one report is the wedge. Several reports on one phone is a list screen, and a list screen before there is a second report is furniture. |
| Upgrading a photographed report to a scanned one later | v1.1. Needs two signatures over two encodings in one bundle, and the sealing model should be proved on one signature first. |
| iCloud sync between the tenant's own devices | v1.1, and only with CloudKit's private database — still no server of ours. Deferred because a report lives on the phone that made it, and losing that phone is a rarer problem than the ones ahead of it. |
| A server timestamp, or a notary | **Not scheduled**, and the reason is [ADR-0003](adr/0003-the-report-is-evidence-not-proof.md). Listed so the request has somewhere to land. |
| A deduction calculator | **Never.** The app records the condition of a room; what that is worth is between the parties, and the moment the app says a number it is giving legal advice about money. |
| A fourth tier, measured against a reference object in the photograph | **Refused** by [ADR-0004](adr/0004-thirty-things-and-the-line-each-does-not-cross.md). A number that is neither photographed, measured nor scanned is a number with no tier, and the tier beside every number is a rule. |
| Annotating a photograph — a circle round the crack | **Refused.** The annotated image would become the evidence and the original would not be in the bundle. The caption says where the crack is. |
| Who was present, as a field in the report | **Refused.** A field is a change to the encoding, and the encoding never changes. Presence is the counter-signature, or it is nothing. |
| Landlord-side app | Not scheduled. The landlord signs on the tenant's phone, which is the point: one phone, one report, no account. A landlord who wants their own copy has the PDF and the bundle. |

## Built, and why

The thirty of [ADR-0004](adr/0004-thirty-things-and-the-line-each-does-not-cross.md)
land here as each is proved. The list of thirty and the phase that builds each
is in [`ROADMAP.md`](ROADMAP.md).

| | What it is for |
|---|---|
