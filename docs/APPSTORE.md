# App Store listing

What the App Store page says, kept here so `make copy-check` reads it with
the app's own strings: nothing on this page may claim more than the report
does. ADR-0003.

## Name

**Snag — move-in and move-out condition reports**

## Subtitle

Photograph the flat before the argument.

## Description

A Lagos tenant pays a year or two of rent in advance, and a caution fee
against damage. Two years later the landlord inspects, names the damage,
and deducts — and the tenant remembers the cracked tile that was cracked on
move-in day and has nothing to show for it.

Snag makes the record on the day it can still be made. Walk the flat room
by room. Photograph what is wrong and what is fine. Every photograph is
hashed the moment it is taken. Seal the report with a key that never leaves
your phone. Share it as a PDF, or as a sealed bundle that anyone with Snag —
or with the published format and a hundred lines of code — can open and be
told: unaltered since signing, or altered.

- Room templates, from a self-contain to a duplex, so the walk starts with
  the rooms named.
- Prompts for what a Lagos flat has and a tenant forgets: the meter, the
  water heater, the burglary bars, the flush.
- Too dark or blurred? Snag says so before the picture is kept, and offers
  the torch.
- Measure a room by tapping its corners (iPhone XS and later). Scan it into
  a floor plan on a Pro iPhone with LiDAR. Every number carries the word for
  how it was made.
- The landlord or agent counter-signs on your phone, in front of you.
- Move out with the move-in photograph beside the new one, and a page that
  says what changed.
- A PDF in Inter with a QR code that matches a printed copy to the bundle it
  came from.
- English, Naijá, Yorùbá, Hausa and Igbo, chosen in the app.
- Nothing is sent anywhere. No account. No server. Your reports stay on your
  phone unless you share them, or choose to keep a copy in your own iCloud.

Snag records the condition of a flat as both sides saw it. It does not say
what anyone owes, and it does not decide a dispute. It gives you the record
you wish you had.

## Keywords

tenant, landlord, rent, Lagos, inventory, inspection, move in, move out,
caution fee, condition report, Nigeria

## Privacy

**Data Not Collected.** Snag has no server and no analytics. Photographs and
reports stay on the phone. The optional iCloud copy goes to the user's own
private CloudKit database under their Apple ID, where Snag cannot read it.

| Permission | Why |
|---|---|
| Camera | to photograph the rooms, measure them, and scan them |
| Calendar (write only) | one optional note on the day the tenancy ends |
| Face ID | the optional app lock |
| Notifications (provisional) | one optional quiet note if a report is still a draft a day later |

## What's new — 1.1

Five languages, chosen in the app. A sealed report can be measured or
scanned later, as a second signature beside the first. A copy in your own
iCloud, if you turn it on.
