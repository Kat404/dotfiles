"""Tests for is_text_likely_untranslated (REQ-073)."""

from __future__ import annotations

import pytest

from translate_epub_ai import is_text_likely_untranslated


@pytest.mark.parametrize(
    "text,expected",
    [
        # 1. pure English → True  2. pure Spanish → False  3. <8 words → False
        # 4. equal counts → False (eng must STRICTLY exceed)
        ("the quick brown fox and the lazy dog were there when they would have said", True),
        ("el perro marrón rápido y el zorro perezoso estaban allí cuando habrían dicho", False),
        ("the and were with", False),
        ("the el and la with en they los there sus when del", False),
    ],
)
def test_is_text_likely_untranslated(text: str, expected: bool) -> None:
    assert is_text_likely_untranslated(text) is expected
