# ADR-0003 — The report is evidence, not proof

**Status:** accepted
**Date:** 2026-09-12

## Context

The first thing a tenant will want to say with a Snag report is *"this proves
the tile was cracked when I moved in."* The app has a signature, a hash, a
timestamp and a photograph, and it would be easy to write a PDF that says
*proof* on the front.

It would not be true. A signature by a key in the phone's Secure Enclave proves
that **these bytes have not changed since the key signed them**. It proves
nothing about *when* they were signed, because the timestamp inside the bytes
came from the phone's own clock, which the tenant can set. There is no server,
so there is no third-party time. There is no notary. A landlord's lawyer will
say this in the first minute, and they will be right.

The obvious fixes are the wrong product. A server timestamp means a backend,
an account and a company that holds evidence about people's homes. A
blockchain anchor means a fee and a dependency on a network Nigerian tenants
do not use. Both trade the thing that makes Snag usable on day one for a claim
the app does not need to make.

What a signed, hashed, photographed, counter-signed report *is*, is evidence:
the best record either party has, made when it could still be made honestly,
and provably unedited since. In a Nigerian tenancy dispute — most of which
never reach a court and are settled by who has the more convincing story —
that is worth a great deal. It is just not proof.

## Decision

**The report says what it proves and what it does not, in the report.**

- The PDF's last page is *What this report is*, in plain language: the
  photographs were taken by this app and hashed at the moment of capture; the
  report was sealed by a key that never left the phone; it has not been
  altered since; the date and time are the phone's own; the counter-signature,
  if present, is a name, a phone number and a drawn signature captured on this
  phone in the presence of the tenant.
- The words *proof*, *proves*, *proven*, *certified*, *notarised* and
  *verified* do not appear in any user-facing string or in the PDF.
  `make copy-check` fails the build on any of them. *Unaltered since signing*
  is what the verifier says, and it is exactly what is true.
- The app never estimates, suggests or calculates a deduction, a repair cost,
  or what a landlord may or may not withhold. That is the fintech line and the
  legal-advice line, and it is the same line.
- A server timestamp, a notary, or an anchoring service is a different
  product with its own ADR and its own privacy policy. This one has neither.

## Consequences

**The most obvious sentence is refused, permanently**, and the reason is
written where the request will be made — including on the PDF, so the tenant
is not surprised by it in the argument.

**The counter-signature carries more weight than the cryptography**, and the
design reflects that: Phase 4 is about getting the other party's name on it,
and R3 is about watching that happen. A report the landlord signed is
evidence the landlord has to explain away. A report only the tenant signed
is evidence the tenant made.

**The honest version is still the best available.** Nothing else a Nigerian
tenant can do on move-in day produces a dated, ordered, hashed, unalterable
record with a floor plan. The report does not need to be proof to be the thing
that wins the conversation.
