#!/usr/bin/env python3
"""Fail if DESIGN.md disagrees with the design tokens it documents.

`CLAUDE.md` says *read `DESIGN.md` before making any visual decision*, which
makes it the authority — and an authority nothing checks is a comment. Two
directions, because one of them is the direction that actually rots:

1.  Every row in the colour table matches the constant the app really uses.
2.  Every colour the app defines appears in the table. A palette gains a role
    far more often than it changes one.

Then the rest of the system — type, targets, radii, spacing — read from the
Swift files that define them and compared with the sentences that quote them.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PALETTE = ROOT / "Snag" / "Design" / "Palette.swift"
TYPE = ROOT / "Snag" / "Design" / "Type.swift"
TARGET = ROOT / "Snag" / "Design" / "Target.swift"
DESIGN = ROOT / "DESIGN.md"

GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"


def theme(source: str, which: str) -> dict[str, object]:
    start = source.index(f"static let {which} = Palette(")
    body = source[start:source.index("\n    )", start)]
    roles: dict[str, object] = {}
    for name, hexv in re.findall(r"(\w+): Color\(hex: 0x([0-9A-Fa-f]{6})\)", body):
        roles[name] = f"#{hexv.upper()}"
    m = re.search(r"canvas: \[(.*?)\]", body, re.DOTALL)
    if m:
        roles["canvas"] = [f"#{h.upper()}" for h in re.findall(r"0x([0-9A-Fa-f]{6})", m.group(1))]
    return roles


def numbers(text: str) -> set[int]:
    return {int(n) for n in re.findall(r"\d+", text)}


def sentence(design: str, opening: str) -> str:
    """The passage from [opening] to its full stop, read with line wraps collapsed."""
    flat = re.sub(r"\s+", " ", design)
    start = flat.index(opening)
    return flat[start:flat.index(".", start)]


def main() -> int:
    source = PALETTE.read_text()
    design = DESIGN.read_text()
    light, dark = theme(source, "light"), theme(source, "dark")
    failures: list[str] = []

    if not light or light.keys() != dark.keys():
        print(f"{RED}✗{RESET} could not parse both themes out of Palette.swift")
        return 1

    # 1. Every row in the table says what the palette says.
    rows: dict[str, tuple[str, str]] = {}
    for role, l, d in re.findall(r"^\| `(\w+)` \| `(#[0-9A-Fa-f]{6})` \| `(#[0-9A-Fa-f]{6})` \|", design, re.MULTILINE):
        rows[role] = (l.upper(), d.upper())
    for name, (l, d) in sorted(rows.items()):
        if name not in light:
            failures.append(f"DESIGN.md documents `{name}`, which Palette.swift does not define")
        elif (l, d) != (light[name], dark[name]):
            failures.append(f"`{name}` is {l}/{d} in DESIGN.md and {light[name]}/{dark[name]} in Palette.swift")

    # 2. Every colour the palette defines is documented.
    for name in sorted(light):
        if name == "canvas":
            stops = list(light["canvas"]) + list(dark["canvas"])
            missing = [s for s in stops if s not in design.upper()]
            if missing:
                failures.append(f"canvas stops {', '.join(missing)} appear nowhere in DESIGN.md")
        elif name not in rows:
            failures.append(f"Palette.swift defines `{name}`, which DESIGN.md never names")

    # Type: the four sizes, from Type.swift, against the sentence that lists them.
    tsrc = TYPE.read_text()
    tbody = tsrc[tsrc.index("enum Type {"):tsrc.index("static let family")]
    sizes = {int(v) for v in re.findall(r"static let \w+: CGFloat = (\d+)", tbody)}
    said = numbers(sentence(design, "Display "))
    if sizes != said:
        failures.append(f"the type scale is {sorted(sizes)} in Type.swift and {sorted(said)} in DESIGN.md")

    # Target, radii, spacing.
    trg = TARGET.read_text()
    standard = re.search(r"static let standard: CGFloat = (\d+)", trg)
    claimed = re.search(r"`Target\.standard` is \*\*(\d+) pt\*\*", re.sub(r"\s+", " ", design))
    if not standard or not claimed:
        failures.append("could not read Target.standard from both sides")
    elif standard.group(1) != claimed.group(1):
        failures.append(f"Target.standard is {standard.group(1)} in Target.swift and {claimed.group(1)} in DESIGN.md")

    radii = {int(v) for v in re.findall(r"static let \w+: CGFloat = (\d+)", trg[trg.index("enum Radius"):trg.index("enum Gap")])}
    if radii != numbers(sentence(design, "Radii:")):
        failures.append(f"the corner radii are {sorted(radii)} in Target.swift and {sorted(numbers(sentence(design, 'Radii:')))} in DESIGN.md")

    gaps = {int(v) for v in re.findall(r"static let \w+: CGFloat = (\d+)", trg[trg.index("enum Gap"):])}
    if gaps != numbers(sentence(design, "Spacing on a four-point grid")):
        failures.append(f"the spacing grid is {sorted(gaps)} in Target.swift and DESIGN.md says otherwise")

    # Dynamic Type: every font in the app is relative to a text style. A
    # `.system(size:)` or a `.custom(_, size:)` without `relativeTo:` is a
    # fixed size the user's setting cannot reach, and the audit's own check
    # for this is not trusted (see SnagUITests) — so the source is.
    fixed: list[str] = []
    for swift in sorted((ROOT / "Snag").rglob("*.swift")):
        if swift.name in ("ReportPDF.swift",):     # paper has no Dynamic Type
            continue
        for n, line in enumerate(swift.read_text().splitlines(), 1):
            if re.search(r"\.system\(size:", line) or (re.search(r"\.custom\(", line) and "relativeTo:" not in line):
                fixed.append(f"{swift.relative_to(ROOT)}:{n}: {line.strip()}")
    if fixed:
        failures.append("fixed font sizes, which Dynamic Type cannot scale:\n    " + "\n    ".join(fixed))

    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}design gate failed{RESET} — DESIGN.md is what a person reads.")
        return 1
    print(f"{GREEN}✓{RESET} DESIGN.md agrees with the tokens: {len(rows)} colour roles and the gradient, "
          "the type scale, the target, the radii and the spacing grid, and every font scales")
    return 0


if __name__ == "__main__":
    sys.exit(main())
