"""Tests for extract_json_from_response (REQ-071)."""

from __future__ import annotations

import pytest

from translate_epub_ai import extract_json_from_response


@pytest.mark.parametrize(
    "raw,expected_id",
    [
        # 1. think strip  2. markdown fence  3. happy path  4. fallback any-object
        # 5. nested braces  6. malformed → raw text unchanged
        ('<think>reasoning</think>{"translations":[{"id":0,"html":"<p>x</p>"}]}', 0),
        ('```json\n{"translations":[{"id":1,"html":"<p>y</p>"}]}\n```', 1),
        ('{"translations":[{"id":2,"html":"<p>z</p>"}]}', 2),
        ('{"data":{"id":3,"html":"<p>w</p>"}}', 3),
        ('{"translations":[{"id":4,"html":"<p>a {curly} b</p>"}]}', 4),
        ("not json at all", "not json at all"),
    ],
)
def test_extract_json_from_response(raw: str, expected_id) -> None:
    out = extract_json_from_response(raw)
    if expected_id == "not json at all":
        assert out == "not json at all"
    else:
        # JSON output strips whitespace; match both forms.
        assert f'"id":{expected_id}' in out or f'"id": {expected_id}' in out
