# ADR-0004 — Thirty things, and the line each one does not cross

**Status:** accepted
**Date:** 2026-09-14

## Context

Phase 1 sealed its first report tonight: a walk, photographs hashed at
capture, a review, a signature by a key that never leaves the phone, a PDF, a
verifier that has seen every byte of every file flipped. The request that
followed was to make the product special — thirty more things — and, as with
Tender, the answer is neither to refuse on principle nor to let the gate list
grow until nothing ships.

Snag's rules are not "one feature". They are the seven in `CLAUDE.md`: the
encoding never changes, evidence never proof, the tier beside every number,
nothing sent, never a number about money, the domain imports nothing, iOS
only. A feature that passes all seven and serves the tenant in the doorway
is not scope creep. One that fails any of them is, however small.

One rule bites harder here than it did in Tender. **The canonical encoding
never changes**, so no feature may add a field to the report. A thing worth
recording goes in a caption, in an item, in a room, or in its own signed
layer beside the report as the counter-signature already is. Version 2 of
the encoding is a decision for another ADR, and none of the thirty needs it.

## Decision

**Thirty features were proposed and each was checked against the seven rules
before it was built.** They are listed in [`ROADMAP.md`](../ROADMAP.md) under
the phase that builds them and in [`FEATURE-BACKLOG.md`](../FEATURE-BACKLOG.md)
under *Built, and why* as each lands. The lines they do not cross:

- **The encoding never changes.** Room templates make rooms; prompts and
  meter readings make items with captions; keys are an item; who was there
  is the counter-signature or nothing. The move-out link uses the field the
  encoding already has. The fixture is unchanged by all thirty.
- **Evidence, never proof.** The QR on the cover carries the id and the key
  fingerprint so a paper copy can be matched to a bundle; it does not say the
  paper is true. `copy-check` reads every new string.
- **The tier beside every number.** A meter reading is a caption, and a
  caption is not a number the app made; the timeline's minutes are the
  phone's clock and say so.
- **Nothing sent.** The zip travels through the share sheet; the reminder is
  a local notification; the calendar entry is the tenant's own calendar; the
  Live Activity is on the tenant's Lock Screen; Siri intents run on the
  phone; backup goes to Files. `network-check` still passes.
- **Never a number about money.** Meter readings are units and cubic metres.
  The diff page says *changed*, never what changed costs.
- **The domain imports nothing.** Compare, the move-out diff, the timeline
  arithmetic and the duplicate-photograph rule are domain code with property
  tests; the app wires them.
- **iOS only.** The torch, Core Haptics, App Intents, Live Activities,
  PencilKit, LocalAuthentication, Vision, EventKit — each is the platform's
  own, which is why ADR-0001 chose it.

**What was refused**, and why, is in the backlog: a fourth tier measured
against a reference object (a number with no tier is a number about
nothing); photograph annotation (the annotated image would be the evidence
and the original would not); a presence field (a field is an encoding change;
presence is the counter-signature); a deduction calculator, permanently.

**The gate list did not grow.** None of the thirty adds a release gate. The
counter-signature, the move-out diff and the calendar reminder are watched
under R3's handover, which already exists.

## Consequences

**The walk gets faster, which is the product.** Templates, prompts and meter
readings cut the number of decisions a tenant makes in the doorway; edit and
delete before the seal mean a wrong photograph is not a wrong report.

**The paper gets checkable.** Page numbers, the contact sheet and the QR turn
a printed PDF into something that can be matched to the bundle it came from.
The second verifier, in Python, from the format document alone, is the proof
that the format document is enough.

**Phase 1 is bigger and Phase 4 starts earlier.** Eighteen of the thirty are
Phase 1's: the walk and the paper. Six are Phase 4's: the handover and the
move-out. Six are Phase 5's: the agent with five flats, the lock, the
reminders. Phases 2 and 3 are untouched; they wait on handsets as before.

**Tests before screens, as before.** Each feature's rule lives in the domain
where it can; the app wires it; a UI test proves it under the audit at two
text sizes on the headless simulator. A feature that needs a sensor is proved
as far as the simulator reaches, with a fixture, and says so.
