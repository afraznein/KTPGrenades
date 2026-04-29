"""Path constants for KTPGrenades config-parse tests.

Mirrors KTPInfrastructure/tests/config_parse/conftest.py.
"""
from __future__ import annotations

from pathlib import Path

# tests/config_parse/conftest.py → repo root
REPO_ROOT = Path(__file__).resolve().parents[2]
