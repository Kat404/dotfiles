"""Test: output EPUB lands next to input, independent of CWD (REQ-078)."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

from translate_epub_ai import EPUBInspector, UniversalBatchTranslator, process_universal_epub


def test_output_path_independent_of_cwd(
    sample_epub_path: Path, tmp_path: Path, llm_stub: MagicMock, monkeypatch
) -> None:
    elsewhere = tmp_path / "elsewhere"
    elsewhere.mkdir(exist_ok=True)
    monkeypatch.chdir(elsewhere)
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)
    info = EPUBInspector(sample_epub_path).extract_info()
    work = sample_epub_path.parent / "work"
    out = sample_epub_path.parent / f"{sample_epub_path.stem} (Español).epub"
    profile = {
        "title": "X",
        "glossary": {},
        "characters": [],
        "never_translate_names": [],
        "keywords": [],
    }
    ck = sample_epub_path.parent / "ck.json"
    tr = UniversalBatchTranslator(
        client=llm_stub, model="m", profile=profile, checkpoint_file=ck, context_window=3
    )
    process_universal_epub(
        input_path=sample_epub_path,
        output_path=out,
        translator=tr,
        inspector_info=info,
        work_dir=work,
        batch_size=2,
    )
    assert out.exists() and not (Path.cwd() / out.name).exists()
