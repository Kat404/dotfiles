"""Argparse tests: REQ-014's CLI flags are recognized + regression guards.

Each flag, when present, lets argparse proceed; main() then exits 1 on the
absent --input. If argparse rejected the flag, main() would exit 2.

Also asserts that the legacy --resume / --no-resume flags are NOT accepted
anymore (BLAKE3-native; cache IS the resume signal).
"""

from __future__ import annotations

import pytest

from translate_epub_ai import main as cli_main


@pytest.mark.parametrize(
    "argv_extra",
    [
        ["--output-dir", "/tmp/x"],
        ["--validate"],
        ["--state-dir", "/tmp/state"],
        ["--strict-toc"],
    ],
)
def test_flag_recognized_by_argparse(monkeypatch, argv_extra: list[str]) -> None:
    monkeypatch.setattr("sys.argv", ["translate_epub_ai.py", *argv_extra, "--api-key", "test"])
    with pytest.raises(SystemExit) as exc:
        cli_main()
    assert exc.value.code == 1  # argparse OK + downstream missing --input


@pytest.mark.parametrize("removed_flag", ["--resume", "--no-resume"])
def test_removed_flags_rejected(monkeypatch, removed_flag: str) -> None:
    """--resume / --no-resume were removed in the BLAKE3-native refactor.

    argparse exits with code 2 on unknown flags.
    """
    monkeypatch.setattr("sys.argv", ["translate_epub_ai.py", removed_flag, "--api-key", "test"])
    with pytest.raises(SystemExit) as exc:
        cli_main()
    assert exc.value.code == 2  # argparse rejected the flag
