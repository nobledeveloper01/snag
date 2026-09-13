# ADR-0001 — Snag is native Swift, and iOS only

**Status:** accepted
**Date:** 2026-09-12

## Context

The portfolio's rule is one codebase for both platforms, and six projects
follow it. Tender broke it first, for a reason recorded in its own ADR-0001:
its user lives in the accessibility layer, which is the platform's own. Snag
is the second exception and needs its own case, because "Tender did it" is
not a reason.

The obvious way to build a condition-report app is React Native or Flutter
with a camera plugin, a PDF library and a signature pad. That produces the
photographs tier — rooms, items, pictures, a PDF — on both platforms, and it
would be a reasonable product.

It cannot produce the other two tiers. **RoomPlan** — a LiDAR walk that yields
a dimensioned floor plan — is a native framework with no cross-platform
binding, and no equivalent exists on Android at all. **ARKit** measurement has
a Flutter plugin that lags releases by a year and exposes a fraction of the
API. And the thing that makes the report worth anything — a signature over a
canonical encoding by a key in the **Secure Enclave** — is CryptoKit and
`SecKey`, reachable from a cross-platform framework only through a native
module, at which point the native module is the product.

So the choice was between a cross-platform app that photographs rooms and a
native app that measures and scans them. The first exists; it is called the
camera roll with better filing. The second is the reason to build anything.

## Decision

**Snag is written in Swift, with SwiftUI, and ships on iOS only.** No Android
version is planned, and the product statement says so in its last section.

The exception is bounded the same way Tender's is. It applies because the
product's distinguishing tiers exist only as native iOS frameworks, and one of
them only on Pro hardware. A condition-report app *could* be cross-platform;
this one is not, because a photographs-only tier is not what is being built.

**Three tiers, and the app names the tier beside every number.** A phone with
LiDAR scans. A phone with an A12 measures. Any phone photographs. The report
never lets a reader mistake a photographed room for a measured one.

What stays the same as everywhere else: the pure domain in its own package
([ADR-0002](0002-the-domain-imports-nothing-from-the-platform.md)), the
documentation gate, the roadmap with exit gates, the release ledger, the
journal, the animated splash, and `make ci` as the only definition of green.

## Consequences

**Android tenants are not served**, and in Nigeria that is most tenants. It is
accepted because the tenants paying the largest caution fees are
disproportionately the ones with iPhones, and because the alternative was a
product with its best two tiers removed.

**The best tier needs a Pro phone.** Most iPhone owners in Nigeria do not have
one. The product is complete without it — that is Phase 3's last clause — and
the ARKit tier on an ordinary iPhone is already more than anything else offers.

**RoomPlan and ARKit do not run in a simulator.** Two of five phases have exit
gates that need a handset, and the ledger says so from day one rather than
discovering it at the end.

**The tooling is Apple's.** `xcodebuild`, `swift test`, `xccov`. No Docker
target; CI on a macOS runner with a pinned Xcode.
