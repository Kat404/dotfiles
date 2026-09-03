"""REQ-012: --output-dir routes output EPUB to the specified directory.

Runs the full `main()` end-to-end with a stub LLM and a pre-existing
profile, then asserts the output EPUB is at <output_dir>/<stem> (Español).epub
and NOT at <input_dir>/<stem> (Español).epub.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from unittest.mock import MagicMock

from tests.conftest import SAMPLE_EPUB_PATH
from translate_epub_ai import compute_file_sha
from translate_epub_ai import main as cli_main


def test_output_dir_routes_to_specified_directory(
    tmp_path: Path, monkeypatch, llm_stub: MagicMock, stub_profile
) -> None:
    in_dir, out_dir, state_dir = tmp_path / "in", tmp_path / "out", tmp_path / "state"
    in_dir.mkdir()
    out_dir.mkdir()
    input_path = in_dir / "book.epub"
    shutil.copy(SAMPLE_EPUB_PATH, input_path)

    # Pre-create profile to skip LLM-based profile generation.
    profile_dir = state_dir / compute_file_sha(input_path)
    profile_dir.mkdir(parents=True)
    profile_dir.joinpath("profile.json").write_text(json.dumps(stub_profile), encoding="utf-8")

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)
    monkeypatch.setattr("translate_epub_ai.get_client", lambda **kw: llm_stub)
    monkeypatch.setattr(
        "sys.argv",
        [
            "translate_epub_ai.py",
            "--input",
            str(input_path),
            "--output-dir",
            str(out_dir),
            "--api-key",
            "test",
            "--state-dir",
            str(state_dir),
        ],
    )
    cli_main()

    expected = out_dir / "book (Español).epub"
    assert expected.exists(), f"output EPUB not at {expected}"
    assert not (in_dir / "book (Español).epub").exists(), "output leaked into input dir"
