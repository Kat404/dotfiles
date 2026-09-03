"""Tests for UniversalBatchTranslator.translate_batch (REQ-075, T25). MagicMock LLM; sleep patched."""

from __future__ import annotations

import json
from unittest.mock import MagicMock

import pytest

from translate_epub_ai import UniversalBatchTranslator, build_checkpoint_key, compute_paragraph_hash

EMPTY = {
    "title": "X",
    "glossary": {},
    "characters": [],
    "never_translate_names": [],
    "keywords": [],
}


def _tr(tmp_path, profile=None, cache=None, ctx=3):
    client = MagicMock()
    ck = tmp_path / "ck.json"
    if cache:
        ck.write_text(json.dumps(cache))
    return UniversalBatchTranslator(
        client=client, model="m", profile=profile or EMPTY, checkpoint_file=ck, context_window=ctx
    )


def _item(idx, text="<p>hello</p>"):
    h = compute_paragraph_hash(text)
    return {
        "id": idx,
        "html": text,
        "cache_key": build_checkpoint_key("ch1.xhtml", h),
        "dom_element": None,
    }


def _mock(client, body):
    client.chat.completions.create.return_value = MagicMock(
        choices=[MagicMock(message=MagicMock(content=body))]
    )


def _ok(items, html="<lang>{0}</lang>"):
    return json.dumps(
        {"translations": [{"id": it["id"], "html": html.format(it["id"])} for it in items]}
    )


@pytest.fixture(autouse=True)
def _no_sleep(monkeypatch):
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)


def test_cache_hit_skips_llm(tmp_path):
    item = _item(0)
    tr = _tr(tmp_path, cache={item["cache_key"]: "<p>cached</p>"})
    assert tr.translate_batch([item])[0]["translated_html"] == "<p>cached</p>"
    tr.client.chat.completions.create.assert_not_called()


def test_cache_miss_calls_llm_and_writes_cache(tmp_path):
    item = _item(0, "<p>hello world</p>")
    tr = _tr(tmp_path)
    _mock(tr.client, _ok([item]))
    tr.translate_batch([item])
    tr.client.chat.completions.create.assert_called_once()
    assert item["cache_key"] in tr.cache and "<lang>0</lang>" in tr.cache[item["cache_key"]]


def test_malformed_retries_then_subdivides(tmp_path):
    tr = _tr(tmp_path)
    _mock(tr.client, "not json")
    tr.translate_batch([_item(0), _item(1)], context_note="batch")
    # 2 parent retries + 2 sub-calls × 2 retries = 6.
    assert tr.client.chat.completions.create.call_count == 6 and tr.cache == {}


def test_subdivision_recursion_sub1_sub2(tmp_path):
    tr = _tr(tmp_path)
    tr.client.chat.completions.create.side_effect = ValueError("boom")
    tr.translate_batch([_item(i) for i in range(4)], context_note="batch")
    msgs = [
        c.kwargs["messages"][1]["content"] for c in tr.client.chat.completions.create.call_args_list
    ]
    assert any("(sub 1)" in m for m in msgs) and any("(sub 2)" in m for m in msgs)


def test_sliding_window_context_injection(tmp_path):
    a, b = _item(0, "<p>first paragraph here</p>"), _item(1, "<p>second paragraph here</p>")
    tr = _tr(tmp_path, ctx=3)
    _mock(tr.client, _ok([a]))
    tr.translate_batch([a], context_note="chapter")
    _mock(tr.client, _ok([b]))
    tr.translate_batch([b], context_note="chapter")
    second = tr.client.chat.completions.create.call_args_list[1].kwargs["messages"][1]["content"]
    assert "<context_note>" in second


def test_glossary_growth(tmp_path):
    profile = {**EMPTY, "characters": [{"name": "Narrador", "gender": "Hombre", "role": "N"}]}
    tr = _tr(tmp_path, profile=profile)
    _mock(tr.client, json.dumps({"translations": [{"id": 0, "html": "<p>El Narrador habló.</p>"}]}))
    tr.translate_batch([_item(0, "<p>The Narrador spoke.</p>")])
    g = tr.profile.get("glossary", {})
    assert "Narrador" in g and "Narrador" in g["Narrador"]


def test_empty_translation_fallback(tmp_path):
    """Whitespace-only translation is accepted by translator; DOM guard in
    process_universal_epub is what skips it (see test_end_to_end)."""
    item = _item(0, "<p>original text here</p>")
    tr = _tr(tmp_path)
    _mock(tr.client, json.dumps({"translations": [{"id": 0, "html": "<p>   </p>"}]}))
    tr.translate_batch([item])
    assert item["cache_key"] in tr.cache
