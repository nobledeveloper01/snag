# Handset day

Everything Snag can prove on a simulator is proved. What is left needs a
phone, a room, a doorway and four readers. This is the list, in the order
that costs least — one phone clears most of it in an afternoon.

## Before leaving the desk

```bash
make ci                       # green on the simulator first
make device-check D=<udid>    # the on-device tests, with the phone plugged in
```

`xcrun xctrace list devices` prints the udid. The device tests are the ones
that skip on a simulator; they run the camera, ARKit and, on a Pro, RoomPlan.

## R1 — the measured tier (any iPhone from 2018, XS or later)

1. A room with a tape measure. Measure the floor with the tape: width,
   length, and multiply.
2. In Snag: a new report, the room, *Measure this room*. Wait for *Tap
   each corner of the floor* — the phone has found the floor. Tap the four
   corners, standing still for each.
3. Compare. The gate is **within five per cent** of the tape. Note the
   light: a Lagos flat with the power off is the design floor, so once in
   daylight and once with the torch.
4. Also on this phone, in the same hour: the viewfinder (the shutter opens
   a live preview, the torch beside it); the torch itself; Face ID lock in
   Settings; the Live Activity on the Lock Screen while a walk is open; the
   Home Screen quick action with the app already in memory; Siri, "Start a
   Snag report"; iCloud — turn on *Keep a copy in my iCloud*, *Sync now*,
   and open the same Apple ID's second device if there is one.

## R2 — the scanned tier (iPhone 12 Pro or any later Pro)

1. The same room, tape-measured.
2. *Scan this room*. Walk slowly with the camera on the walls until the
   room closes. Check the plan: the door and the window where they are.
3. The gate: the scan's area within five per cent of the tape **and** of the
   ARKit measurement from R1. A phone without LiDAR must see no *Scan*
   button and nothing else missing.
4. Amend: on a report sealed with *photographed* only, *Measure or scan
   later*, scan the room, seal the amendment. The first seal must still
   read *Unaltered since signing*; the PDF's cover must say *Amended on*.

## R3 — a real handover

A tenant moving in and the landlord or agent, in the doorway, one phone.
Watch, do not help. Note every question either of them asks the phone that
the phone does not answer. The counter-signature on glass, the PDF shared to
the other party's WhatsApp, the bundle opened on their phone if they have
Snag. Two years of rent is on the table; this is the hour the whole product
was designed for.

## R4 — a lawyer's hour

Somebody who has argued a Lagos tenancy case reads the PDF — the cover, a
room page, the diff page, the counter-signature page and the last page — and
is asked one question: *does any sentence here claim more than it can?*
Not whether it is admissible. Every sentence they mark goes back to
`ReportText.swift` and the copy gate.

## R5 — the four translations

A native speaker of each of Naijá, Yorùbá, Hausa and Igbo, an hour each,
with the app in their hand and the language chosen in Settings: the walk,
the item sheet, the sealed screen, and the last page of the PDF. The
English stays above the translation on that page until this is done, and
the picker says the translation is a draft.

## When a gate clears

Move its row from *Blocks v1.0* to *Cleared* in `docs/RELEASE-GATES.md`,
with the date and who watched it. `make counts-check` will make the README
agree.
