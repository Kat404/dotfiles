"""Persistence tests: resume after kill + checkpoint roundtrip + atomic failure (REQ-079)."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from translate_epub_ai import (
    EPUBInspector,
    UniversalBatchTranslator,
    atomic_write_json,
    build_checkpoint_key,
    compute_paragraph_hash,
    process_universal_epub,
)

_PROF = {
    "title": "X",
    "glossary": {},
    "characters": [],
    "never_translate_names": [],
    "keywords": [],
    "synopsis_translated": "ES.",
}


def _run(epub_path, ck, client):
    info = EPUBInspector(epub_path).extract_info()
    tr = UniversalBatchTranslator(
        client=client, model="m", profile=_PROF, checkpoint_file=ck, context_window=3
    )
    process_universal_epub(
        input_path=epub_path,
        output_path=ck.parent / "out.epub",
        translator=tr,
        inspector_info=info,
        work_dir=ck.parent / "work",
        batch_size=2,
    )


def test_resume_after_kill_skips_llm_for_cached(
    sample_epub_path: Path, llm_stub: MagicMock, monkeypatch
) -> None:
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)
    ck = sample_epub_path.parent / "ck.json"
    c2 = MagicMock()
    c2.chat.completions.create.side_effect = llm_stub.chat.completions.create.side_effect
    _run(sample_epub_path, ck, llm_stub)
    n1 = llm_stub.chat.completions.create.call_count
    _run(sample_epub_path, ck, c2)
    assert n1 > 0 and c2.chat.completions.create.call_count < n1


def test_checkpoint_roundtrip_skips_llm(tmp_path: Path) -> None:
    ck = tmp_path / "ck.json"
    text = "<p>hello world paragraph here for hashing</p>"
    key = build_checkpoint_key("ch1.xhtml", compute_paragraph_hash(text))
    atomic_write_json(ck, {key: "<p>cached translation</p>"})
    tr = UniversalBatchTranslator(
        client=MagicMock(), model="m", profile=_PROF, checkpoint_file=ck, context_window=3
    )
    out = tr.translate_batch([{"id": 0, "html": text, "cache_key": key, "dom_element": None}])
    assert out[0]["translated_html"] == "<p>cached translation</p>"
    tr.client.chat.completions.create.assert_not_called()


def test_atomic_write_failure_preserves_original(tmp_path: Path, monkeypatch) -> None:
    target = tmp_path / "ck.json"
    atomic_write_json(target, {"k": "v1"})
    monkeypatch.setattr(
        "translate_epub_ai.os.replace", lambda *_a, **_kw: (_ for _ in ()).throw(OSError("crash"))
    )
    with pytest.raises(OSError):
        atomic_write_json(target, {"k": "v2"})
    assert json.loads(target.read_text()) == {"k": "v1"}
    assert not (tmp_path / "ck.json.tmp").exists()
