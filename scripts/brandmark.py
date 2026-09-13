#!/usr/bin/env python3
"""Draw the Snag mark: the app icon and docs/mark.png.

The same shape `Snag/Brand/Mark.swift` draws at runtime — a banknote, its
portrait window, and three pulses (short, short, long) — so the icon on the
home screen, the mark on the splash and the one above the README title are
one drawing. The colours are the palette's: `ready` on the dark `surface`,
read out of Palette.swift rather than copied, so a palette change cannot
leave the icon behind.

    make brandmark        writes the files
    make splash-check     fails if they are stale
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    print("Pillow is needed: python3 -m pip install --user Pillow", file=sys.stderr)
    sys.exit(2)

import os

ROOT = Path(__file__).resolve().parent.parent
PALETTE = ROOT / "Snag" / "Design" / "Palette.swift"
# `splash-check` redraws into a temporary directory to compare, so the
# outputs can be redirected without touching the tree.
_OUT = Path(os.environ["SNAG_BRANDMARK_OUT"]) if "SNAG_BRANDMARK_OUT" in os.environ else None
ICON = (_OUT / "icon-1024.png") if _OUT else ROOT / "Snag" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"
MARK = (_OUT / "mark.png") if _OUT else ROOT / "docs" / "mark.png"


def dark_palette() -> dict[str, tuple[int, int, int]]:
    src = PALETTE.read_text()
    start = src.index("static let dark = Palette(")
    body = src[start:src.index("\n    )", start)]
    out = {}
    for name, hexv in re.findall(r"(\w+): Color\(hex: 0x([0-9A-Fa-f]{6})\)", body):
        out[name] = tuple(int(hexv[i:i + 2], 16) for i in (0, 2, 4))
    return out


def draw(size: int, ground: tuple[int, int, int] | None, ink: tuple[int, int, int]) -> Image.Image:
    """A room from above, its door, and the snag: the same shape Snag/Brand/Mark.swift draws."""
    s = size * 4
    img = Image.new("RGBA", (s, s), (*ground, 255) if ground else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = h = s
    stroke = max(2, int(w * 0.045))
    room = (w * 0.18, h * 0.18, w * 0.82, h * 0.82)
    d.rounded_rectangle(room, radius=int(w * 0.09), outline=ink, width=stroke)
    # The door: a gap in the bottom wall, painted over in the ground colour.
    gap = (w * 0.40, h * 0.82 - stroke, w * 0.60, h * 0.82 + stroke)
    d.rectangle(gap, fill=(*ground, 255) if ground else (0, 0, 0, 0))
    # The snag: a crack, three short segments, upper right.
    pts = [(w * 0.56, h * 0.30), (w * 0.62, h * 0.40), (w * 0.57, h * 0.47), (w * 0.66, h * 0.58)]
    d.line(pts, fill=ink, width=stroke, joint="curve")
    return img.resize((size, size), Image.LANCZOS)


def main() -> int:
    p = dark_palette()
    ink, ground = p["accent"], p["surface"]
    ICON.parent.mkdir(parents=True, exist_ok=True)
    draw(1024, ground, ink).convert("RGB").save(ICON)      # App Store icons carry no alpha
    MARK.parent.mkdir(parents=True, exist_ok=True)
    draw(256, None, ink).save(MARK)
    print(f"\033[0;32m✓\033[0m drew the mark: {ICON} and {MARK}" if _OUT else f"\033[0;32m✓\033[0m drew the mark: {ICON.relative_to(ROOT)} and {MARK.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
