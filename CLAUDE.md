# Snag

A move-in and move-out condition report for Nigerian tenancies. **iOS only, in
Swift, by decision** — read `docs/adr/0001-snag-is-native-and-ios-only.md`
before asking why there is no Android build. Read `docs/00-PRODUCT-STATEMENT.md`
for why this exists, `docs/ROADMAP.md` for what phase the project is in and
what its exit gate is, and `docs/adr/` for the decisions that are already
settled. `PHASE` holds the current phase number.

The one sentence that decides most arguments:

> **The evidence is the wedge, not the dispute.**

The dispute happens in two years to one tenant in ten. What every tenant does
on move-in day is walk the flat and notice what is wrong, and Snag is the
fastest way to write that down. A report is worth making for one tenant with
no landlord on the other side, on day one; the two-sided version is what it
becomes when landlords learn tenants arrive with one.

## Design system

Read `DESIGN.md` before making any visual or UI decision. Colour, type,
spacing and target sizes are defined there. Do not deviate without explicit
approval.

**The design floor is a dim flat with the power off, one hand holding the
phone while the other points at the crack, a landlord waiting in the doorway,
and a tenant who has just paid two years' rent and wants this over with.**
Everything follows from it: the walk is fast, every step is one tap, and
nothing asks a question that can be answered later.

## The things that are never traded

1. **The canonical encoding never changes.** Every signature ever made is over
   it. A checked-in fixture asserts it byte-for-byte, and a change to that
   fixture is a change to what *altered* means for every report in the world.
   ADR-0002.
2. **Evidence, never proof.** The report says what it proves and what it does
   not, on its own last page. `make copy-check` fails the build on the words
   that would claim more. ADR-0003.
3. **The tier is beside every number.** Photographed, measured or scanned. A
   reader never mistakes one for another, and a phone without LiDAR is never
   told it is missing something.
4. **Nothing is sent.** No server, no account, no analytics. The report is the
   tenant's, on the tenant's phone, and it leaves only through the share sheet
   in the tenant's hand.
5. **Never a number about money.** No deduction, no repair estimate, no
   deposit calculation. That is the fintech line and the legal-advice line and
   they are the same line.
6. **The domain imports nothing.** Not Foundation. The Swift standard library
   only. Enforced by `make domain-purity`, which is proved to fire. ADR-0002.
7. **iOS only.** No Android. A request for one is answered by ADR-0001, not by
   a port.

## Working on this repo

- `make ci` is the gate. `make gates` runs the blocking ones alone.
- **Prove a guard fires before trusting it.** Break it on purpose, watch it
  fail, put it back. This has found real defects in every project in this
  portfolio, including gates written the same hour. The verifier especially:
  a verifier that has never seen a tampered file is one nobody knows the
  behaviour of.
- **A gate that passes for a reason unrelated to what it checks is worse than
  one that cannot fail.** Delete the cache and re-run before believing a green
  result. Check the exit status of `make`, not of the pipeline it is in.
- ADRs live in `docs/adr/`. **Write one for any non-obvious decision, before
  the code that depends on it.**
- **`docs/JOURNAL.md` every working session.** What we did, and what surprised
  us.
- The domain package tests with `swift test` in seconds and needs no
  simulator. Run it first.
- **Never commit a `.snag` file.** A report made while developing is somebody's
  flat. `.gitignore` refuses them; the fixture is synthetic.

## Definition of done

- [ ] Acceptance criteria met and demonstrated on a device
- [ ] Every number in the report carries its tier
- [ ] Canonical-encoding fixture unchanged, or an ADR says why it changed
- [ ] Verifier proved against a tampered bundle if sealing was touched
- [ ] Verified on a physical iPhone; RoomPlan on a LiDAR one
- [ ] Light and dark authored; every pair contrast-asserted in CI
- [ ] 200% text scaling without truncation — check it, do not assume it
- [ ] Screen-reader labelled; colour never the sole carrier of meaning
- [ ] Every error path has a forward path — no dead ends
- [ ] **Copy reviewed for overclaiming** — `make copy-check` green, and a
      person has read what the PDF says it proves
- [ ] ADR written for any non-obvious decision
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `make ci` green
