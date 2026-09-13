# Snag — Product Statement

**A move-in and move-out condition report for Nigerian tenancies. Scan the room,
photograph what is wrong, get a dated report both sides sign — months before the argument
about the caution fee.**

---

## The Problem

In Lagos a tenant pays a year or two of rent in advance, plus a **caution fee** — a
deposit, typically one to three months' rent, against damage. When the tenancy ends, the
landlord or agent inspects, names the damage, and deducts. The tenant either accepts the
number or argues about a scuff that was there when they moved in and cannot prove it.

Nobody wrote anything down on the day they moved in. There was no inventory, no
photographs, no signed description of the cracked tile in the bathroom or the window that
never latched. The Lagos Tenancy Law says the deposit is refundable less lawful
deductions; it does not say how anybody is supposed to establish what was there before.
So the person with the money decides.

This is not a Lagos problem. It is the same in Abuja, Port Harcourt and Ibadan, and it is
the same for the landlord: a tenant who leaves a flat wrecked and says it was like that has
the same absence of evidence on their side.

---

## Why Existing Solutions Do Not Work

**Photographs on the phone.** Some tenants take them. They are undated in any way that
would convince anybody, unorganised, in a camera roll with two thousand other pictures, and
the landlord never agreed to them.

**A written inventory.** The UK's answer, and it works there because letting agents are
regulated and deposits are held by a third party. In Nigeria there is no third-party
scheme, most agents are unregulated, and the inventory would be written by the party who
benefits from it being vague.

**The agent's own inspection.** The agent works for the landlord.

**A lawyer.** Costs more than the caution fee.

**Keys (06 in this portfolio)** verifies the listing and the landlord before money changes
hands. It stops the tenant renting a flat that does not exist. It does nothing about what
happens two years later.

---

## The Product

Snag makes the record on the day it can still be made honestly.

1. **Walk** — the tenant walks the flat room by room. On a phone with LiDAR, RoomPlan
   produces a dimensioned floor plan as they walk. On any recent iPhone, ARKit measures the
   rooms. On anything, the rooms are named and photographed. The app says which of the
   three it did, for every number.
2. **Snag** — every defect is a photograph and a sentence: *bathroom, cracked tile below
   the sink*. The photograph is hashed the moment it is taken.
3. **Sign** — the report is a PDF and a signed bundle. The landlord, agent or witness signs
   on the tenant's phone; their name and phone number are in the report. The bundle is
   signed by a key that never leaves the phone's Secure Enclave.
4. **Keep** — the tenant keeps it. AirDrop, email, WhatsApp — the PDF goes anywhere, and
   the bundle can be opened in Snag by anyone to confirm it has not been altered since it
   was signed.
5. **Compare** — at move-out, the same walk, room by room, with the move-in photograph
   beside the new one. What changed is a list. What did not is a longer list.

---

## The Insight

**The evidence is the wedge, not the dispute.**

The dispute happens in two years, to one tenant in ten. Nobody downloads an app for that.
What every tenant does on move-in day is walk the flat and notice what is wrong — and Snag
is the fastest way to write that down, with a floor plan thrown in, which is useful for
furniture before it is useful for anything else.

The report is worth making for one tenant with no landlord on the other side, on day one.
A landlord who will not sign it has still been sent it, dated and hashed, and a report the
landlord ignored is better evidence than no report. The two-sided version — landlord signs,
both keep it, both compare at move-out — is what it becomes when landlords learn that
tenants arrive with one.

---

## Target User

**Primary — the tenant, on move-in day.** Lagos, Abuja, Port Harcourt. Has just paid
somewhere between ₦800,000 and ₦5,000,000 and has the keys. Has an iPhone — which in
Nigeria means they are in the top tier of earners, and also means the caution fee is
serious money to them. Speaks English or Pidgin.

**Secondary — the landlord or agent with several flats.** Wants the same thing from the
other direction, and wants it for five properties.

**Tertiary — the witness.** A friend, a family member, sometimes the caretaker. Signs to
say they were there.

---

## Why Now

- **LiDAR on the iPhone** turned a room into a floor plan in ninety seconds. RoomPlan
  shipped in 2022 and nothing consumer-facing in Nigeria uses it.
- **Rent in advance keeps rising.** The caution fee rises with it. The argument is about
  more money every year.
- **The Lagos Tenancy Law gives the tenant a right** to the deposit less lawful deductions,
  and a growing number of tenants know it. What they lack is the evidence.
- **iPhone owners are exactly the tenants** paying the largest deposits.

---

## Explicitly Not

- **Not an escrow.** Snag never holds, moves or calculates the caution fee. It records the
  condition of a room. What that is worth is between the parties.
- **Not proof.** A signed report proves it has not been altered since it was signed. It
  does not prove *when*, because a phone's clock is a phone's clock and there is no
  server. See [ADR-0003](adr/0003-the-report-is-evidence-not-proof.md). The report says
  so, in the report.
- **Not a letting platform.** No listings, no landlords to browse, no payments. That is
  Keys.
- **Not legal advice.** The app never says what a landlord may deduct.
- **Not cross-platform.** iOS only, by decision, recorded in
  [ADR-0001](adr/0001-snag-is-native-and-ios-only.md). The second of two such projects
  in this portfolio, and the reason is written down.
