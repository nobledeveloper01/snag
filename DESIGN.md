# Snag — design system

**The floor:** a dim flat with the power off, one hand holding the phone while the other
points at the crack, a landlord waiting in the doorway, and a tenant who has just paid two
years' rent and wants this over with. Every rule below follows from it.

## Principles

1. **The walk is the interface.** Room, item, photograph, next. Nothing interrupts it.
2. **One tap per step.** A question that can be answered later is asked later.
3. **The tier is always visible.** A number never appears without the word that says how
   it was made.
4. **Honest about what it is.** *Unaltered since signing*, never *verified*. The PDF says
   what it proves on its own last page.
5. **Calm.** This is a tense hour. Nothing flashes, nothing counts down, nothing warns.

## Colour

Built around the three things a report says about a room: this is fine, this is a snag,
and this has been tampered with.

**Three surface tones, not one.** Depth on a dark screen comes from stepping the surface,
with a hairline where the step alone is too subtle to read in a dim room.

| Role | Light | Dark | |
|---|---|---|---|
| `surface` | `#FAFBFC` | `#0F1012` | The page |
| `raised` | `#FFFFFF` | `#1A1C20` | Cards, the item row |
| `high` | `#EEF1F5` | `#25282E` | Controls on a card |
| `outline` | `#B9C0CC` | `#454A54` | The hairline between them |
| `textPrimary` | `#0F1012` | `#F2F4F7` | |
| `textSecondary` | `#4B5260` | `#A7ADB8` | |
| `accent` | `#0B5CAD` | `#5AB0FF` | The primary action, the current room |
| `onAccent` | `#FFFFFF` | `#06101C` | What is legible **on** the accent |
| `snag` | `#8A4300` | `#FFA24A` | An item that is a defect |
| `fine` | `#1E7A3E` | `#63D68A` | An item recorded as sound; a bundle that verifies |
| `altered` | `#B3261E` | `#FF7B7B` | A bundle that does not |

The page carries a two-stop vertical gradient — `#161A20` to `#0F1012` in the dark,
`#FAFBFC` to `#F1F4F8` in the light — barely apart. **The gradient, not `surface`, is what
text is drawn on**, so the contrast assertions measure every stop.

**Dark is the default**, not the system setting. Both are authored; neither is derived.

**Every pair is asserted in CI**, in both themes, by `SnagTests/ContrastTests.swift`:
4.5:1 for text and 3:1 for the colours that carry state, on every ground including both
gradient stops. The hairline is not asserted; it carries no meaning.

**Colour is never the sole carrier of meaning.** A snag has an icon and the word; a
verified bundle says *unaltered since signing* in words beside the green.

## Targets

`Target.standard` is **56 pt**. `Target.primary` is **64 pt** — the shutter, and *Next
room*, which are pressed with the phone held in one hand at arm's length.

## Shape and spacing

Radii: 16 for tiles, 20 for cards, 12 for chips, fully round for pills and the shutter.
Spacing on a four-point grid — 4, 8, 12, 16, 24, 32.

Every tappable surface scales to 0.96 under the thumb.

**One primary action per screen, pinned below the scroll.** During the walk it is the
shutter, and nothing else at 64 points. Every screen's one primary button is the one the
UI tests name — *New report*, *Walk the flat*, *Add a room*, *Photograph*, *Done*, *Seal*,
*Share PDF*, *Check*, *Counter-sign*, *Use this measurement*, *Use this scan* — and the
screenshots in the README are the eye's check at 100%; `.textClipped` at the largest size
is the machine's.

## Type

**Inter, bundled** — one variable file, every weight, as in every cross-platform project in
this portfolio. Bundled rather than system because the report's PDF is set in the same face
as the app, and a PDF that renders in whatever the reader's machine has is a document that
looks different on the landlord's laptop.

Every `fontWeight` is accompanied by the variable axis, so a weight the file does not carry
is a build error rather than a fallback.

Display 22 pt, headline 18, title 17, body 15, secondary 14, with a single 13 for marks that
only qualify something already legible — a tier chip, a hash prefix, a timestamp. Dynamic
Type honoured to 200%; the walk is asserted without truncation at that size.

## The tier chip

Every number in the app and in the PDF is followed by one of three chips, in
`textSecondary` on `high`, never coloured:

| Chip | Means |
|---|---|
| **photographed** | A room named and photographed. No dimensions |
| **measured** | ARKit: the tenant tapped the corners. ±5% |
| **scanned** | RoomPlan: a LiDAR walk. A floor plan exists |

A phone that cannot scan never sees the word *scanned*, and never sees a greyed-out
control for it. For that tenant it does not exist.

## The report

The PDF is the product's face on a table. A4, Inter, one room per page, photographs at
a size a crack is visible in, the tier chip beside every dimension, the plan on its own page
if there is one, signatures on the last page but one, and *What this report is* on the last
— the plain-language statement of what a signature proves and what it does not
([ADR-0003](docs/adr/0003-the-report-is-evidence-not-proof.md)).

The words *proof, proves, proven, certified, notarised, verified* do not appear anywhere
in the app or the PDF. `make copy-check` fails the build on any of them.

## Motion

The splash is the portfolio's: the mark, a warm bloom, the wordmark, about 1.2 seconds,
driven by a timer and not by an animation so that Reduce Motion gets a still for the same
duration. The launch screen is painted `#0F1012` so there is no white flash on handover.

During the walk, nothing moves except the shutter's press and the room list advancing.
The verifier's result fades in over 200 ms so *altered* is not a jump-scare in an already
tense conversation.
