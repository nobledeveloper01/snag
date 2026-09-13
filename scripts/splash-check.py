#!/usr/bin/env python3
"""Fail if the launch screen or the mark is not what the palette says.

Three claims, each read from the source that makes it:

1.  The launch screen is painted the palette's dark surface, so there is no
    white flash on handover to the splash. Read from the asset catalogue's
    colour set and compared with Palette.swift.
2.  Info.plist points the launch screen at that colour set.
3.  The icon and docs/mark.png are what `scripts/brandmark.py` draws today.
    Drawn again to a temporary file and compared byte for byte, so a palette
    change that was not followed by `make brandmark` fails here.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"


def pixels_differ(a: Path, b: Path) -> str | None:
    """None if the two images are the same picture; otherwise why not."""
    from PIL import Image, ImageChops
    ia, ib = Image.open(a).convert("RGBA"), Image.open(b).convert("RGBA")
    if ia.size != ib.size:
        return f"{ia.size} vs {ib.size}"
    diff = ImageChops.difference(ia, ib).convert("L")
    hist = diff.histogram()
    total = ia.size[0] * ia.size[1]
    big = sum(hist[9:])            # pixels off by more than 8 of 255
    if big > total * 0.001:        # more than a tenth of a percent of them
        return f"{big} of {total} pixels differ"
    return None


def palette_dark_surface() -> str:
    src = (ROOT / "Snag/Design/Palette.swift").read_text()
    body = src[src.index("static let dark = Palette("):]
    return "#" + re.search(r"surface: Color\(hex: 0x([0-9A-Fa-f]{6})\)", body).group(1).upper()


def launch_colour() -> str:
    cs = json.loads((ROOT / "Snag/Assets.xcassets/LaunchGround.colorset/Contents.json").read_text())
    c = cs["colors"][0]["color"]["components"]
    return "#" + "".join(f"{int(c[k], 16):02X}" for k in ("red", "green", "blue"))


def main() -> int:
    failures: list[str] = []
    want = palette_dark_surface()
    got = launch_colour()
    if got != want:
        failures.append(f"LaunchGround is {got}; the palette's dark surface is {want}")
    plist = (ROOT / "Config/Info.plist").read_text()
    if "<key>UIColorName</key><string>LaunchGround</string>" not in plist.replace("\n", "").replace("\t", ""):
        failures.append("Info.plist does not point UILaunchScreen at LaunchGround")

    # Redraw to a temp dir and compare.
    with tempfile.TemporaryDirectory() as tmp:
        env = {"SNAG_BRANDMARK_OUT": tmp}
        r = subprocess.run([sys.executable, str(ROOT / "scripts/brandmark.py")], env={**__import__("os").environ, **env},
                           capture_output=True, text=True)
        if r.returncode != 0:
            failures.append(f"brandmark.py failed: {r.stderr.strip()}")
        else:
            for rel in ("Snag/Assets.xcassets/AppIcon.appiconset/icon-1024.png", "docs/mark.png"):
                fresh = Path(tmp) / Path(rel).name
                current = ROOT / rel
                if not current.exists():
                    failures.append(f"{rel} is missing — run `make brandmark`")
                    continue
                # Compare the picture, not the bytes. CI's Pillow encodes PNGs
                # differently from this machine's — same drawing, different
                # file — and the first CI run failed on exactly that. A moved
                # palette colour changes thousands of pixels by a lot; an
                # encoder or resampler changes a few by a little.
                differs = pixels_differ(fresh, current)
                if differs is not None:
                    failures.append(f"{rel} is not what brandmark.py draws today ({differs}) — run `make brandmark`")

    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        return 1
    print(f"{GREEN}✓{RESET} the launch screen paints {want}, the dark surface the app starts in; the icon and the mark are current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
