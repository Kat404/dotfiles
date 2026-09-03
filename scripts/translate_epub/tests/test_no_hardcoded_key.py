"""Security test: no hardcoded API key in production code (REQ-077)."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "translate_epub_ai.py"


def test_no_sk_pattern_in_source() -> None:
    text = SCRIPT.read_text(encoding="utf-8")
    pattern = re.compile(r"sk-[a-zA-Z0-9]{20,}")
    offenders = [(i + 1, line) for i, line in enumerate(text.splitlines()) if pattern.search(line)]
    assert not offenders, f"hardcoded key candidates: {offenders}"


def test_script_exits_1_without_api_key(sample_epub_path: Path) -> None:
    # Real EPUB so EPUBInspector doesn't crash before API key check.
    env = {k: v for k, v in os.environ.items() if k != "AI_API_KEY"}
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--input", str(sample_epub_path)],
        capture_output=True,
        text=True,
        env=env,
        timeout=15,
    )
    assert proc.returncode == 1, f"expected exit 1, got {proc.returncode}\nstderr={proc.stderr}"
    assert "AI_API_KEY" in proc.stderr
