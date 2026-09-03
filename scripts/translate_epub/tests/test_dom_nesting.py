"""Regression: DOM <p> nesting — real LLM returns <p> wrappers; stubs return <lang> (REQ-062, T34).

Bug fixed: dom_el.clear(); for child in new_contents.contents: dom_el.append(child)
would produce <p class="foo"><p>X</p></p> when LLM wrapped translation in <p>.
Fix: if dom_el is <p> and child is <p>, unwrap the child (append its children, extract it).
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

from translate_epub_ai import (
    EPUBInspector,
    UniversalBatchTranslator,
    process_universal_epub,
)


def test_dom_injection_unwraps_nested_p(
    sample_epub_path: Path, stub_profile: dict[str, Any], monkeypatch
) -> None:
    """End-to-end: LLM stub returns <p>X</p>; output must not contain <p><p>."""

    def _fake(*_a, **kw):
        content = kw["messages"][1]["content"]
        items = json.loads(content[content.rfind("[\n") :])
        # Realistic LLM behavior: wraps each translation in <p>...</p>.
        out = [{"id": it["id"], "html": f"<p>HOLA_{it['id']}</p>"} for it in items]
        return MagicMock(
            choices=[MagicMock(message=MagicMock(content=json.dumps({"translations": out})))]
        )

    client = MagicMock()
    client.chat.completions.create.side_effect = _fake
    monkeypatch.setattr("translate_epub_ai.time.sleep", lambda *_a, **_kw: None)

    info = EPUBInspector(sample_epub_path).extract_info()
    work = sample_epub_path.parent / "work_nest"
    out = sample_epub_path.parent / "nest_out.epub"
    ck = sample_epub_path.parent / "ck_nest.json"
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
    import zipfile

    with zipfile.ZipFile(out, "r") as z:
        ch1 = z.read("ch1.xhtml").decode("utf-8")
    # Translated text present.
    assert "HOLA_0" in ch1 or "HOLA_1" in ch1
    # No <p><p> nesting anywhere in the spine file.
    assert "<p><p>" not in ch1, f"nested <p><p> detected in output. Excerpt:\n{ch1[:500]}"
    # The original <p class="chapter-opening" id="p1"> attribute must still be preserved.
    assert 'class="chapter-opening"' in ch1
    assert 'id="p1"' in ch1


def test_dom_injection_preserves_attrs_when_unwrapping() -> None:
    """Unit-level: simulating the injection logic on a single BS4 tree."""
    from bs4 import BeautifulSoup

    src = '<html><body><p class="foo">original text</p></body></html>'
    soup = BeautifulSoup(src, "html.parser")
    p = soup.find("p")
    preserved_attrs = {"class": "foo", "id": "p1"}
    # LLM returns <p>wrapped</p> — real-world output.
    trans_html = "<p>HOLA TRADUCIDO</p>"
    new_contents = BeautifulSoup(trans_html, "html.parser")
    p.clear()
    for child in list(new_contents.contents):
        if p.name == "p" and getattr(child, "name", None) == "p":
            for grandchild in list(child.contents):
                p.append(grandchild)
            child.extract()
        else:
            p.append(child)
    for k, v in preserved_attrs.items():
        if k not in p.attrs:
            p.attrs[k] = v
    rendered = str(p)
    assert "<p><p>" not in rendered
    assert "HOLA TRADUCIDO" in rendered
    assert 'class="foo"' in rendered
    assert 'id="p1"' in rendered


def test_dom_injection_passthrough_non_p_child() -> None:
    """Non-<p> children append unchanged (no over-aggressive unwrap)."""
    from bs4 import BeautifulSoup

    soup = BeautifulSoup("<html><body><p>x</p></body></html>", "html.parser")
    p = soup.find("p")
    trans_html = "<b>bold translated</b>"
    new_contents = BeautifulSoup(trans_html, "html.parser")
    p.clear()
    for child in list(new_contents.contents):
        if p.name == "p" and getattr(child, "name", None) == "p":
            for gc in list(child.contents):
                p.append(gc)
            child.extract()
        else:
            p.append(child)
    rendered = str(p)
    assert rendered == "<p><b>bold translated</b></p>"
    assert "<p><p>" not in rendered


def test_dom_injection_multiple_p_children() -> None:
    """Multiple sibling <p>s from LLM each unwrap to plain text nodes."""
    from bs4 import BeautifulSoup

    soup = BeautifulSoup("<html><body><p>orig</p></body></html>", "html.parser")
    p = soup.find("p")
    trans_html = "<p>one</p><p>two</p>"
    new_contents = BeautifulSoup(trans_html, "html.parser")
    p.clear()
    for child in list(new_contents.contents):
        if p.name == "p" and getattr(child, "name", None) == "p":
            for gc in list(child.contents):
                p.append(gc)
            child.extract()
        else:
            p.append(child)
    rendered = str(p)
    assert "<p><p>" not in rendered
    assert "one" in rendered and "two" in rendered
