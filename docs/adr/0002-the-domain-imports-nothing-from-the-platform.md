# ADR-0002 — The domain imports nothing from the platform

**Status:** accepted
**Date:** 2026-09-12

## Context

Snag's centre of gravity is a document that will be put on a table in an
argument about money. What a report contains. What order its rooms and items
are in. Which bytes, exactly, a signature covers. What *altered* means. What a
tier is and what a number from each tier is allowed to claim.

None of that is a screen and none of it needs a camera, a LiDAR sensor or a
Secure Enclave. All of it is what the product *is*.

The obvious way to build it is to let the report model reach for `Foundation`
— `Date`, `JSONEncoder`, `UUID`, `Data` — and for `CryptoKit` to hash as it
goes. Each is one line. Together they make the one thing that must never
change — the canonical encoding — depend on the platform's encoder, whose
output has changed between OS versions before, and on a clock the domain
should not own.

The specific failure this guards against: a report signed on iOS 17 whose
`JSONEncoder` emits keys in one order, opened on iOS 19 where it emits them in
another, and verified as *altered* by an app that did nothing wrong. The
signature is over bytes. The domain has to own the bytes.

## Decision

**`SnagDomain/` is a Swift package that imports nothing.** The Swift standard
library only. Not Foundation, not CryptoKit.

- The domain defines `Report`, `Room`, `Item`, `Tier`, `Party`, `Signature`
  and the **canonical encoding**: `Report.canonicalBytes() -> [UInt8]`, a
  hand-written, length-prefixed, field-ordered serialisation with no
  dependency on any encoder, asserted byte-stable against a checked-in
  fixture.
- Hashing and signing are the app's job. The domain says *these bytes*; the
  app's `Sealing` module says *this SHA-256, this P-256 signature*. The domain
  never sees a key.
- Time arrives as an argument — seconds since an epoch, as an integer — and a
  photograph arrives as its hash, already computed by the app.
- `make domain-purity` reads every file under `SnagDomain/Sources/` and fails
  on any `import`, or on `Date(`, `DispatchTime`, `ProcessInfo`, `random`,
  `arc4random` or `UUID(`. It runs inside `make analyze`.
- The package tests with `swift test` on macOS, no simulator, in seconds.

**The gate is proved by breaking it.** Each banned thing must turn it red.

## Consequences

**The canonical encoding is written by hand and is boring.** That is the
feature. A format that a person can read a spec of and re-implement in another
language is a format a court's expert can verify without this app.

**Identifiers are not UUIDs.** A report's id is the hash of its first
canonical encoding, computed by the app and handed back. Nothing in the domain
needs randomness.

**The 95% coverage floor is cheap**, because the domain is a data model and an
encoder, both of which are pure and total.

**It reads imports and call sites, not the dependency graph.** A package with
no imports has no transitive problem.
