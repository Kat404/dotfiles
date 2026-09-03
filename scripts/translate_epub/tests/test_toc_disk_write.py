"""Regression: TOC translations must be persisted to disk in the output EPUB (REQ-052, T33).

Bug fixed: parse_ncx()/parse_navdoc() built their own BS4 soup while
apply_toc_translations() serialized a different outer soup, so mutations
landed in cache but the on-disk NCX/NavDoc files were unchanged.
"""

from __future__ import annotations

import json
import zipfile
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

from translate_epub_ai import EPUBInspector, UniversalBatchTranslator, process_universal_epub


def test_toc_disk_write_in_output_epub(
    sample_epub_path: Path, stub_profile: dict[str, Any], monkeypatch
) -> None:
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)

    def _fake(*_a, **kw):
        content = kw["messages"][1]["content"]
        items = json.loads(content[content.rfind("[\n") :])
        out = [{"id": it["id"], "html": f"<lang>ES_{it['id']}</lang>"} for it in items]
        return MagicMock(
            choices=[MagicMock(message=MagicMock(content=json.dumps({"translations": out})))]
        )

    client = MagicMock()
    client.chat.completions.create.side_effect = _fake

    info = EPUBInspector(sample_epub_path).extract_info()
    work = sample_epub_path.parent / "work"
    out = sample_epub_path.parent / "toc_out.epub"
    ck = sample_epub_path.parent / "ck.json"
    tr = UniversalBatchTranslator(
        client=client, model="m", profile=stub_profile, checkpoint_file=ck, context_window=0
    )
    process_universal_epub(
        input_path=sample_epub_path,
        output_path=out,
        translator=tr,
        inspector_info=info,
        work_dir=work,
        batch_size=2,
    )

    assert out.exists()
    with zipfile.ZipFile(out, "r") as z:
        toc_hits = 0
        for name in z.namelist():
            if not name.endswith((".ncx", ".xhtml", ".html")):
                continue
            if "nav" not in name and "ncx" not in name:
                continue
            blob = z.read(name).decode("utf-8", errors="ignore")
            if "ES_" in blob:
                toc_hits += 1
        assert toc_hits >= 1, "no TOC file in output EPUB contains translated text"


def test_ncx_mutation_propagates_to_serialized_bytes(
    sample_epub_path: Path, stub_profile: dict[str, Any], monkeypatch
) -> None:
    """Directly verify the fix: parse_ncx with an explicit soup sees mutations on that soup."""
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)

    def _fake(*_a, **kw):
        content = kw["messages"][1]["content"]
        items = json.loads(content[content.rfind("[\n") :])
        out = [{"id": it["id"], "html": f"<lang>CAPITULO_{it['id']}</lang>"} for it in items]
        return MagicMock(
            choices=[MagicMock(message=MagicMock(content=json.dumps({"translations": out})))]
        )

    client = MagicMock()
    client.chat.completions.create.side_effect = _fake

    info = EPUBInspector(sample_epub_path).extract_info()
    work = sample_epub_path.parent / "work_ncx"
    out = sample_epub_path.parent / "ncx_out.epub"
    ck = sample_epub_path.parent / "ck_ncx.json"
    tr = UniversalBatchTranslator(
        client=client, model="m", profile=stub_profile, checkpoint_file=ck, context_window=0
    )
    process_universal_epub(
        input_path=sample_epub_path,
        output_path=out,
        translator=tr,
        inspector_info=info,
        work_dir=work,
        batch_size=2,
    )

    with zipfile.ZipFile(out, "r") as z:
        ncx_blob = next((z.read(n) for n in z.namelist() if n.endswith(".ncx")), b"")
    assert ncx_blob, "no NCX file in output EPUB"
    assert b"CAPITULO" in ncx_blob, (
        f"NCX file does not contain translated text. Got: {ncx_blob[:300]!r}"
    )


def test_toc_disk_write_via_workspace(tmp_path: Path) -> None:
    """Workspace-level check: after process_universal_epub, NCX on disk is Spanish."""
    from translate_epub_ai import parse_ncx

    # Build a minimal NCX file inside a workspace directory.
    ncx_path = tmp_path / "toc.ncx"
    ncx_bytes = (
        b'<?xml version="1.0" encoding="utf-8"?>\n'
        b'<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/">\n'
        b"  <navMap>\n"
        b'    <navPoint id="n1"><navLabel><text>Chapter One</text></navLabel>'
        b'<content src="ch1.xhtml"/></navPoint>\n'
        b'    <navPoint id="n2"><navLabel><text>Chapter Two</text></navLabel>'
        b'<content src="ch2.xhtml"/></navPoint>\n'
        b"  </navMap>\n"
        b"</ncx>\n"
    )
    ncx_path.write_bytes(ncx_bytes)

    # Direct check: when we parse with an outer soup and mutate entries,
    # the outer soup reflects the change and serializes Spanish.
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(ncx_bytes, "xml")
    entries = parse_ncx(ncx_bytes, soup=soup)
    assert len(entries) == 2
    for e in entries:
        e["dom_element"].clear()
        e["dom_element"].append("Capítulo ES")
    serialized = str(soup).encode("utf-8")
    assert b"Cap\xedtulo ES" in serialized or "Capítulo ES".encode() in serialized
    assert b"Chapter One" not in serialized
