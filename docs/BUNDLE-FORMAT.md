# The bundle format

A sealed report leaves the phone as a directory named `<id>.snag`, where
`<id>` is the lower-case hex of the SHA-256 of `report.bin`. Everything a
reader needs to check it is inside; nothing needs the phone that made it, the
app that made it, or a network.

```
<id>.snag/
  report.bin        the canonical bytes of the report (docs/adr/0002)
  report.sig        ECDSA P-256 over SHA-256(report.bin), DER encoded
  key.pub           the signing public key, X9.63 (65 bytes, uncompressed)
  photos/
    <sha256>.jpg    every photograph, named by the hex of its own SHA-256
  countersign.bin   (optional) canonical bytes of the counter-signature
  countersign.sig   (optional) ECDSA over SHA-256(countersign.bin), same key
  signature.jpg     (with the above) the drawn signature; its SHA-256 is the
                    counter-signature's signatureHash
  amendment.bin     (optional) u8 version=1, 32 bytes the original's id,
                    i64 amendedAt, then the canonical bytes of the amended
                    report — numbers and plans added after the seal
  amendment.sig     (with the above) ECDSA over SHA-256(amendment.bin), same key
```

The same files travel as one file, `<id>.snagz`: a zip archive of the
directory with the entries stored or deflated. A verifier accepts either.

## What the verifier checks

In this order, and the first failure is the answer:

1. `report.bin`, `report.sig` and `key.pub` are present — else *not a bundle*.
2. `key.pub` parses as a P-256 public key; `report.sig` parses as DER.
3. The signature verifies over `SHA-256(report.bin)` with that key.
4. `report.bin` decodes as a version-1 report.
5. Every `photoHash` and `planHash` in the report names a file in `photos/`
   whose bytes hash to its name. A photograph in `photos/` that the report
   does not name is also a failure: a bundle carries nothing it did not sign.
6. If `amendment.bin` is present, `amendment.sig` verifies over it with the
   same key, it decodes, its original id equals `<id>`, and the amended
   report changes nothing but each room's numbers and plan — the same rooms,
   items, captions, address and date, and no room's tier lowered. The report
   a reader is then shown is the amended one; step 5 checks the photographs
   of both. The original's seal is untouched and still verifies alone.
7. If `countersign.bin` is present, `countersign.sig` verifies over it with
   the same key, it decodes, its `reportId` equals `<id>`, and
   `signature.jpg` is present and hashes to its `signatureHash`.

Any failure after step 1 is *altered*. There is no third answer, because a
partial verdict is an invitation to argue about which part.

## What is and is not signed

The signature is over `report.bin` only. The photographs are bound to it by
their hashes, which are inside `report.bin`. The public key is not signed by
anything: the bundle says *this key signed this report*, not *this person*.
Who held the phone is what the counter-signature, the tenancy agreement and
the people in the room establish; the bundle establishes that nothing in it
changed after the seal. ADR-0003.

The PDF is not part of the bundle and is not signed. It is a rendering of
`report.bin` for people who read paper, and its last page says so.

## A second verifier

`scripts/verify.py` is this document, in Python, with P-256 written out
from its constants and no dependencies. `make verify-check` runs it against
a bundle the app sealed — `SnagTests/Fixtures/bundle-v1` — and against eight
tampers of it, every time. If the app and the script ever disagree, one of
them has drifted from this page.

## The key

P-256, made on first seal, in the Secure Enclave where the phone has one and
otherwise as a software key stored in the Keychain under the account
`ng.snag.sealing-key`. It never leaves the phone; the bundle carries only the
public half. A phone with a Secure Enclave cannot export the private key at
all. Losing the phone loses the key, and every bundle already sealed stays
verifiable because each carries its public key.

## Stability

`report.bin` is the canonical encoding of ADR-0002 and is fixed by the
checked-in fixture `SnagDomain/Tests/SnagDomainTests/Fixtures/report-v1.bin`.
The file names and layout above are version 1 and change only with a new
version byte in `report.bin` and an ADR.
