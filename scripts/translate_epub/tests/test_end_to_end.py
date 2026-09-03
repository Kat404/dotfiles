"""End-to-end test for process_universal_epub (REQ-076, T26). Runs offline and <10s."""

from __future__ import annotations

import json
import re
import zipfile
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

from translate_epub_ai import EPUBInspector, UniversalBatchTranslator, process_universal_epub


def test_end_to_end_translates_fixture(
    sample_epub_path: Path, stub_profile: dict[str, Any], llm_stub: MagicMock, monkeypatch
) -> None:
    def _fake(*_a, **kw):
        content = kw["messages"][1]["content"]
        items = json.loads(content[content.rfind("[\n") :])
        out = [
            {
                "id": it["id"],
                "html": f"<lang>{re.sub('<[^>]+>', '', it['html']).strip().upper()}</lang>",
            }
            for it in items
        ]
        return MagicMock(
            choices=[MagicMock(message=MagicMock(content=json.dumps({"translations": out})))]
        )

    llm_stub.chat.completions.create.side_effect = _fake
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)

    info = EPUBInspector(sample_epub_path).extract_info()
    work, out, ck = (
        sample_epub_path.parent / "work",
        sample_epub_path.parent / "out.epub",
        sample_epub_path.parent / "ck.json",
    )
    tr = UniversalBatchTranslator(
        client=llm_stub, model="m", profile=stub_profile, checkpoint_file=ck, context_window=3
    )
    assert (
        process_universal_epub(
            input_path=sample_epub_path,
            output_path=out,
            translator=tr,
            inspector_info=info,
            work_dir=work,
            batch_size=2,
        )
        is False
    )
    assert out.exists()
    with zipfile.ZipFile(out, "r") as z:
        assert "mimetype" in z.namelist()  # valid ZIP
        opf = z.read("content.opf").decode("utf-8")
        assert "<dc:language>es</dc:language>" in opf  # dc:language updated
        assert "Descripción traducida al español." in opf  # dc:description updated
        # TOC translation performed (cache populated; disk-write bug — Risks #1)
        assert ck.exists() and any(k.startswith("toc.") for k in json.loads(ck.read_text()))
        ch1 = z.read("ch1.xhtml").decode("utf-8")
        assert 'class="chapter-opening"' in ch1 and 'id="p1"' in ch1  # <p> attrs preserved
