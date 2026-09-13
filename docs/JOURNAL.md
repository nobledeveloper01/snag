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
