#!/usr/bin/env python3
"""
A second verifier, in another language, from docs/BUNDLE-FORMAT.md alone.

    python3 scripts/verify.py <bundle.snag directory | bundle.snagz>

Prints "unaltered" or "altered: <first reason>" or "not a bundle", and
exits 0, 1 or 2. No dependencies beyond the standard library: P-256 and
ECDSA are forty lines of modular arithmetic, written here so that a
court's expert, a landlord's nephew or a CI job can check a bundle with a
stock Python and the format document. If this script and the app ever
disagree, one of them is wrong and the fixture in SnagTests/Fixtures
says which.
"""
import hashlib
import io
import struct
import sys
import zipfile
from pathlib import Path

# --- P-256 ------------------------------------------------------------------
P = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
A = P - 3
B = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B
N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551
GX = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
GY = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5


def inv(x, m):
    return pow(x, m - 2, m)


def add(p, q):
    if p is None:
        return q
    if q is None:
        return p
    (x1, y1), (x2, y2) = p, q
    if x1 == x2 and (y1 + y2) % P == 0:
        return None
    if p == q:
        lam = (3 * x1 * x1 + A) * inv(2 * y1, P) % P
    else:
        lam = (y2 - y1) * inv(x2 - x1, P) % P
    x3 = (lam * lam - x1 - x2) % P
    return (x3, (lam * (x1 - x3) - y1) % P)


def mul(k, p):
    r = None
    while k:
        if k & 1:
            r = add(r, p)
        p = add(p, p)
        k >>= 1
    return r


def on_curve(pt):
    x, y = pt
    return (y * y - (x * x * x + A * x + B)) % P == 0


def ecdsa_verify(pub, digest, r, s):
    if not (1 <= r < N and 1 <= s < N) or not on_curve(pub):
        return False
    e = int.from_bytes(digest, "big")
    w = inv(s, N)
    u1, u2 = e * w % N, r * w % N
    pt = add(mul(u1, (GX, GY)), mul(u2, pub))
    return pt is not None and pt[0] % N == r


# --- encodings --------------------------------------------------------------
def parse_x963(b):
    if len(b) != 65 or b[0] != 4:
        raise ValueError("public key")
    return (int.from_bytes(b[1:33], "big"), int.from_bytes(b[33:], "big"))


def parse_der(b):
    # SEQUENCE { INTEGER r, INTEGER s }
    if len(b) < 8 or b[0] != 0x30:
        raise ValueError("signature encoding")
    i = 2 if b[1] < 0x80 else 3
    out = []
    for _ in range(2):
        if b[i] != 0x02:
            raise ValueError("signature encoding")
        n = b[i + 1]
        out.append(int.from_bytes(b[i + 2:i + 2 + n], "big"))
        i += 2 + n
    return out


class Reader:
    def __init__(self, b):
        self.b, self.i = b, 0

    def take(self, n):
        if self.i + n > len(self.b):
            raise ValueError("truncated")
        v = self.b[self.i:self.i + n]
        self.i += n
        return v

    def u8(self):
        return self.take(1)[0]

    def u16(self):
        return struct.unpack(">H", self.take(2))[0]

    def i32(self):
        return struct.unpack(">i", self.take(4))[0]

    def i64(self):
        return struct.unpack(">q", self.take(8))[0]

    def string(self):
        return self.take(self.u16()).decode("utf-8")

    def hash(self):
        return bytes(self.take(32))

    def opt_hash(self):
        return self.hash() if self.u8() else None

    def opt_dim(self):
        if not self.u8():
            return None
        cm, tier = self.i32(), self.u8()
        if tier > 2:
            raise ValueError("tier")
        return (cm, tier)


def decode_report(b):
    r = Reader(b)
    if r.u8() != 1:
        raise ValueError("version")
    kind = r.u8()
    if kind > 1:
        raise ValueError("kind")
    address, created, moved_in = r.string(), r.i64(), r.opt_hash()
    rooms = []
    for _ in range(r.u16()):
        name = r.u8()
        if name > 7 and name != 255:
            raise ValueError("room name")
        custom = r.string() if name == 255 else None
        dims = (r.opt_dim(), r.opt_dim(), r.opt_dim())
        plan = r.opt_hash()
        items = []
        for _ in range(r.u16()):
            state = r.u8()
            if state > 1:
                raise ValueError("item state")
            photo, caption, taken = r.hash(), r.string(), r.i64()
            if len(caption) > 280:
                raise ValueError("caption")
            items.append({"state": state, "photo": photo, "caption": caption, "takenAt": taken})
        rooms.append({"name": name, "custom": custom, "dims": dims, "plan": plan, "items": items})
    if r.i != len(b):
        raise ValueError("trailing bytes")
    return {"kind": kind, "address": address, "createdAt": created, "movedIn": moved_in, "rooms": rooms}


def decode_amendment(b):
    r = Reader(b)
    if r.u8() != 1:
        raise ValueError("version")
    original, at = r.hash(), r.i64()
    return {"originalId": original, "amendedAt": at, "report": decode_report(bytes(b[41:]))}


def amends_only_numbers(amended, original):
    if (amended["kind"], amended["address"], amended["createdAt"], amended["movedIn"]) != \
       (original["kind"], original["address"], original["createdAt"], original["movedIn"]):
        return False
    if len(amended["rooms"]) != len(original["rooms"]):
        return False
    for a, b in zip(amended["rooms"], original["rooms"]):
        if a["name"] != b["name"] or a["custom"] != b["custom"] or a["items"] != b["items"]:
            return False
        tier = lambda room: max([d[1] for d in room["dims"] if d] or [0])
        if tier(a) < tier(b):
            return False
    return True


def decode_countersign(b):
    r = Reader(b)
    if r.u8() != 1:
        raise ValueError("version")
    out = {"reportId": r.hash(), "name": r.string(), "phone": r.string(), "signature": r.hash(), "signedAt": r.i64()}
    if r.i != len(b):
        raise ValueError("trailing bytes")
    return out


# --- the bundle -------------------------------------------------------------
def load(path):
    """{name: bytes} for a directory or a .snagz."""
    p = Path(path)
    files = {}
    if p.is_dir():
        for f in p.rglob("*"):
            if f.is_file():
                files[str(f.relative_to(p))] = f.read_bytes()
    else:
        with zipfile.ZipFile(io.BytesIO(p.read_bytes())) as z:
            for name in z.namelist():
                if not name.endswith("/"):
                    files[name] = z.read(name)
    return files


def verify(files):
    """'unaltered', 'altered: reason', or 'not a bundle' — the order of docs/BUNDLE-FORMAT.md."""
    for needed in ("report.bin", "report.sig", "key.pub"):
        if needed not in files:
            return "not a bundle"
    try:
        pub = parse_x963(files["key.pub"])
    except ValueError:
        return "altered: public key"
    try:
        r, s = parse_der(files["report.sig"])
    except (ValueError, IndexError):
        return "altered: signature encoding"
    if not ecdsa_verify(pub, hashlib.sha256(files["report.bin"]).digest(), r, s):
        return "altered: report signature"
    try:
        report = decode_report(files["report.bin"])
    except (ValueError, UnicodeDecodeError, struct.error):
        return "altered: report decoding"
    # The amendment layer: same key, the original's id, numbers only.
    current = report
    if "amendment.bin" in files or "amendment.sig" in files:
        if "amendment.bin" not in files or "amendment.sig" not in files:
            return "altered: amendment incomplete"
        try:
            ar, as_ = parse_der(files["amendment.sig"])
        except (ValueError, IndexError):
            return "altered: amendment encoding"
        if not ecdsa_verify(pub, hashlib.sha256(files["amendment.bin"]).digest(), ar, as_):
            return "altered: amendment signature"
        try:
            amendment = decode_amendment(files["amendment.bin"])
        except (ValueError, UnicodeDecodeError, struct.error):
            return "altered: amendment decoding"
        if amendment["originalId"] != hashlib.sha256(files["report.bin"]).digest():
            return "altered: amendment names another report"
        if not amends_only_numbers(amendment["report"], report):
            return "altered: amendment changes more than numbers"
        current = amendment["report"]
    named = set()
    for room in report["rooms"] + current["rooms"]:
        for item in room["items"]:
            named.add(item["photo"])
        if room["plan"]:
            named.add(room["plan"])
    for h in named:
        name = f"photos/{h.hex()}.jpg"
        if name not in files:
            return f"altered: photograph missing {h.hex()[:12]}"
        if hashlib.sha256(files[name]).digest() != h:
            return f"altered: photograph {h.hex()[:12]}"
    for name in files:
        if name.startswith("photos/") and bytes.fromhex(name[7:-4]) not in named:
            return f"altered: stray photograph {name}"
    if "countersign.bin" in files or "countersign.sig" in files:
        if "countersign.bin" not in files or "countersign.sig" not in files:
            return "altered: counter-signature incomplete"
        try:
            cr, cs = parse_der(files["countersign.sig"])
        except (ValueError, IndexError):
            return "altered: counter-signature encoding"
        if not ecdsa_verify(pub, hashlib.sha256(files["countersign.bin"]).digest(), cr, cs):
            return "altered: counter-signature"
        try:
            counter = decode_countersign(files["countersign.bin"])
        except (ValueError, UnicodeDecodeError, struct.error):
            return "altered: counter-signature decoding"
        if counter["reportId"] != hashlib.sha256(files["report.bin"]).digest():
            return "altered: counter-signature names another report"
        if "signature.jpg" not in files:
            return "altered: signature image missing"
        if hashlib.sha256(files["signature.jpg"]).digest() != counter["signature"]:
            return "altered: signature image"
    return "unaltered"


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    verdict = verify(load(sys.argv[1]))
    print(verdict)
    return 0 if verdict == "unaltered" else (2 if verdict == "not a bundle" else 1)


if __name__ == "__main__":
    sys.exit(main())
