#!/usr/bin/env python3
"""Fail if the domain package imports anything, or reaches for the platform.

ADR-0002: `SnagDomain/` imports nothing — not Foundation. The Swift standard
library only. So the rule a gate can read is one line: no `import` statement
of any kind. Stricter than Harvest's Dart rule, which allows a short list, and
affordable because the domain is small and numeric.

The second half is the same everywhere in this portfolio: the clock and the
dice arrive as arguments, never as globals. In Swift the tempting names are
`Date()`, `DispatchTime.now()`, `ProcessInfo`, `.random(` and `arc4random`.
Foundation is banned already, so most of these cannot compile — but the gate
names them anyway, because a gate that relies on the compiler to enforce a
rule it describes is a gate that stops working the day somebody adds an import.

Proved to fire: each banned thing, added on purpose, turns this red.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOMAIN = ROOT / "SnagDomain" / "Sources" / "SnagDomain"

GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"

BANNED = [
    ("Date()", r"\bDate\s*\(", "the clock is an argument in this layer, never a global"),
    ("DispatchTime", r"\bDispatchTime\b", "that is the clock again, wearing a different name"),
    ("ProcessInfo", r"\bProcessInfo\b", "the process is the platform"),
    (".random()", r"\.random\s*\(", "a property test cannot pin down a rule that rolls dice"),
    ("arc4random", r"\barc4random", "a property test cannot pin down a rule that rolls dice"),
]


def code(text: str) -> str:
    """The file with its comments removed, so prose about a rule is not a breach."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("//"))


def main() -> int:
    files = sorted(DOMAIN.rglob("*.swift"))
    if not files:
        print(f"{RED}✗{RESET} no Swift files under {DOMAIN.relative_to(ROOT)} — check the path")
        return 1

    failures: list[str] = []
    for path in files:
        where = path.relative_to(ROOT)
        body = code(path.read_text())
        for module in re.findall(r"^\s*(?:@\w+\s+)?import\s+(\S+)", body, re.MULTILINE):
            failures.append(f"{where} imports {module} — the domain imports nothing, not even Foundation (ADR-0002)")
        for name, pattern, why in BANNED:
            if re.search(pattern, body):
                failures.append(f"{where} uses {name} — {why}")

    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}the domain layer is not pure{RESET} — see ADR-0002.")
        return 1
    print(f"{GREEN}✓{RESET} domain layer is pure Swift — {len(files)} files, no imports, no clock, no randomness")
    return 0


if __name__ == "__main__":
    sys.exit(main())
