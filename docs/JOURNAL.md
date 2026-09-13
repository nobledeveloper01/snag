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
