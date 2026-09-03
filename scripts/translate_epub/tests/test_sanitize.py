"""Tests for sanitize_html_fragment (REQ-072)."""

from __future__ import annotations

import pytest

from translate_epub_ai import sanitize_html_fragment


@pytest.mark.parametrize(
    "raw,probe",
    [
        # 1. valid HTML pass-through  2. unbalanced quotes  3. BS4 fallback
        # 4. empty string  5. None  6. unclosed <p>
        ('<p class="ok">hi</p>', '<p class="ok">hi</p>'),
        ('<p class="bad", id="x">hi</p>', 'class="bad"'),
        ('<p class="weird"<><span>x', "x"),
        ("", ""),
        (None, ""),
        ("<p>only an opening", "only an opening"),
    ],
)
def test_sanitize_html_fragment(raw, probe: str) -> None:
    out = sanitize_html_fragment(raw)
    assert isinstance(out, str)
    if probe:
        assert probe in out
