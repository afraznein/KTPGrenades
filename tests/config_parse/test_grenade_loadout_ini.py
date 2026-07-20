"""Schema validation for `data/grenade_loadout.ini`.

The plugin reads per-class grenade counts from this INI; missing or
malformed entries silently fall back to game-default loadouts. Catches:
  - typos in section names. Sections are cosmetic to the plugin — it skips
    every `[...]` line and matches class names globally — so this test
    enforces `[allies]`/`[axis]`/`[british]` for human readability only,
    not because the plugin distinguishes them.
  - out-of-range counts (header docstring says -1..10; a value of 99 here
    silently saturates at the plugin's MAX without warning)
  - non-integer values
  - duplicate keys (configparser silently last-wins)
"""
from __future__ import annotations

import configparser
import re

import pytest

from .conftest import REPO_ROOT

CONFIG_PATH = REPO_ROOT / "data" / "grenade_loadout.ini"

# Conventional groupings. The plugin ignores section headers entirely and
# resolves class names globally; this set is a readability convention.
ALLOWED_SECTIONS = {"allies", "axis", "british"}

# Range from the file's own header documentation: "-1 or omit entry to use
# game default. Maximum value: 10."
COUNT_MIN = -1
COUNT_MAX = 10


@pytest.fixture(scope="module")
def parsed():
    if not CONFIG_PATH.exists():
        pytest.skip(f"{CONFIG_PATH} not present")
    parser = configparser.ConfigParser(
        # File uses `; comment` after values, e.g. `garand = 1     ; Rifleman`.
        # Without inline_comment_prefixes those become part of the value and
        # int() parsing fails — the plugin's own AMXX parser handles trailing
        # comments, so the test must too.
        inline_comment_prefixes=(";",),
    )
    # Section / option names are case-insensitive in the plugin (per the file's
    # own header) and configparser's default behavior (lowercased options).
    parser.read(CONFIG_PATH, encoding="utf-8")
    return parser


def test_file_parses(parsed):
    assert parsed.sections(), f"{CONFIG_PATH.name}: no sections parsed"


def test_only_allowed_sections_present(parsed):
    extra = set(parsed.sections()) - ALLOWED_SECTIONS
    assert not extra, (
        f"{CONFIG_PATH.name}: unexpected sections {sorted(extra)}; "
        f"only {sorted(ALLOWED_SECTIONS)} are used by convention "
        f"(the plugin ignores sections entirely — this is a readability check)"
    )


def test_at_least_one_team_configured(parsed):
    """A loadout file with no team sections is almost certainly a mistake.
    Doesn't enforce ALL three sections present (deployments may legitimately
    skip [british] if only Axis maps are used) — just that at least one is."""
    present = set(parsed.sections()) & ALLOWED_SECTIONS
    assert present, (
        f"{CONFIG_PATH.name}: no team sections present "
        f"(expected at least one of {sorted(ALLOWED_SECTIONS)})"
    )


def test_all_values_are_integers(parsed):
    """Every value in every team section parses as an integer."""
    bad: list[tuple[str, str, str]] = []
    for section in parsed.sections():
        if section not in ALLOWED_SECTIONS:
            continue
        for cls, val in parsed.items(section):
            try:
                int(val)
            except (TypeError, ValueError):
                bad.append((section, cls, val))
    assert not bad, (
        f"{CONFIG_PATH.name}: non-integer values:\n"
        + "\n".join(f"  [{s}] {c}={v!r}" for s, c, v in bad[:10])
    )


def test_all_counts_in_documented_range(parsed):
    """Counts must fall in the [-1, 10] range the file's own header
    documents. Plugin clamps silently, so this is the only place a
    bad value surfaces."""
    bad: list[tuple[str, str, int]] = []
    for section in parsed.sections():
        if section not in ALLOWED_SECTIONS:
            continue
        for cls, val in parsed.items(section):
            try:
                n = int(val)
            except ValueError:
                continue  # caught by the integer test
            if not (COUNT_MIN <= n <= COUNT_MAX):
                bad.append((section, cls, n))
    assert not bad, (
        f"{CONFIG_PATH.name}: counts outside [{COUNT_MIN}, {COUNT_MAX}]:\n"
        + "\n".join(f"  [{s}] {c}={n}" for s, c, n in bad[:10])
    )


def test_no_duplicate_keys_per_section():
    """ConfigParser silently last-wins on duplicate keys within a section.
    Re-scan the raw file to surface duplicates explicitly."""
    current_section: str | None = None
    seen: dict[str, set[str]] = {}
    dups: list[tuple[str, str]] = []
    section_re = re.compile(r"^\s*\[([^\]]+)\]\s*$")
    kv_re = re.compile(r"^\s*([^=;]+?)\s*=")
    for raw in CONFIG_PATH.read_text(encoding="utf-8").splitlines():
        if section_re.match(raw):
            current_section = section_re.match(raw).group(1).strip().lower()
            seen.setdefault(current_section, set())
            continue
        if current_section is None:
            continue
        # Skip comment + blank lines
        stripped = raw.strip()
        if not stripped or stripped.startswith(";"):
            continue
        m = kv_re.match(raw)
        if not m:
            continue
        key = m.group(1).strip().lower()
        if key in seen[current_section]:
            dups.append((current_section, key))
        seen[current_section].add(key)
    assert not dups, (
        f"{CONFIG_PATH.name}: duplicate keys: "
        + ", ".join(f"[{s}].{k}" for s, k in dups[:10])
    )
