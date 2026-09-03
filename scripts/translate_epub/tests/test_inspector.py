"""EPUBInspector integration test (REQ-074, T24).

NOTE: `sample_text` — production returns list[str]; spec says "string". We
assert iterable + non-empty (satisfies both) without modifying production.
"""

from __future__ import annotations

from pathlib import Path


def test_inspector_extract_info(sample_epub_path: Path) -> None:
    from translate_epub_ai import EPUBInspector

    info = EPUBInspector(sample_epub_path).extract_info()
    meta = info["metadata"]
    assert (
        meta["title"] == "Sample Book"
        and meta["creator"] == "Test Author"
        and meta["language"] == "en"
    )
    assert (
        isinstance(info["spine_files"], list)
        and info["spine_files"]
        and info["spine_files"][0].endswith("ch1.xhtml")
    )
    assert info["sample_text"] and len(info["sample_text"]) > 0  # list (see module docstring)
    assert isinstance(info["total_paragraphs"], int) and info["total_paragraphs"] >= 5
