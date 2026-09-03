"""Tests for TOC parsers (REQ-050, REQ-051, T19, T20)."""

from __future__ import annotations

from translate_epub_ai import (
    feature_detect_toc,
    parse_navdoc,
    parse_ncx,
)

SAMPLE_NCX = b"""<?xml version='1.0' encoding='utf-8'?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="nav1"><navLabel><text>Chapter 1</text></navLabel>
      <content src="ch1.xhtml"/></navPoint>
    <navPoint id="nav2"><navLabel><text>Chapter 2</text></navLabel>
      <content src="ch2.xhtml"/></navPoint>
    <navPoint id="nav3"><navLabel><text></text></navLabel>
      <content src="empty.xhtml"/></navPoint>
  </navMap>
</ncx>
"""


SAMPLE_NAVDOC = b"""<?xml version='1.0' encoding='utf-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
<nav epub:type="toc">
  <ol>
    <li><a href="ch1.xhtml">Chapter 1</a></li>
    <li><a href="ch2.xhtml">Chapter 2</a></li>
  </ol>
</nav>
<nav epub:type="landmarks">
  <ol><li><a href="cover.xhtml">Cover</a></li></ol>
</nav>
</body>
</html>
"""


def test_parse_ncx_collects_text_with_ids() -> None:
    entries = parse_ncx(SAMPLE_NCX)
    assert len(entries) == 2
    assert entries[0]["text"] == "Chapter 1"
    assert entries[0]["navpoint_id"] == "nav1"
    assert entries[1]["text"] == "Chapter 2"
    assert entries[1]["navpoint_id"] == "nav2"


def test_parse_ncx_skips_empty_text() -> None:
    entries = parse_ncx(SAMPLE_NCX)
    texts = [e["text"] for e in entries]
    assert "" not in texts
    assert "Chapter 1" in texts and "Chapter 2" in texts


def test_parse_ncx_no_navmap_returns_empty() -> None:
    assert parse_ncx(b"<root><text>nope</text></root>") == []
    assert parse_ncx(b"") == []


def test_parse_ncx_dom_element_is_writable() -> None:
    entries = parse_ncx(SAMPLE_NCX)
    tag = entries[0]["dom_element"]
    tag.clear()
    tag.append("Capítulo 1")
    assert "Capítulo 1" in str(tag)


def test_parse_navdoc_collects_a_with_href() -> None:
    entries = parse_navdoc(SAMPLE_NAVDOC)
    assert len(entries) == 2
    assert entries[0]["text"] == "Chapter 1"
    assert entries[0]["href"] == "ch1.xhtml"
    assert entries[1]["text"] == "Chapter 2"
    assert entries[1]["href"] == "ch2.xhtml"


def test_parse_navdoc_ignores_landmarks() -> None:
    entries = parse_navdoc(SAMPLE_NAVDOC)
    hrefs = [e["href"] for e in entries]
    assert "cover.xhtml" not in hrefs


def test_parse_navdoc_no_toc_nav_returns_empty() -> None:
    assert parse_navdoc(b"<html><body><nav><a>x</a></nav></body></html>") == []
    assert parse_navdoc(b"") == []


def test_parse_navdoc_preserves_href_on_write() -> None:
    entries = parse_navdoc(SAMPLE_NAVDOC)
    tag = entries[0]["dom_element"]
    href = tag.get("href", "")
    tag.clear()
    if href:
        tag["href"] = href
    tag.append("Capítulo 1")
    out = str(tag)
    assert 'href="ch1.xhtml"' in out
    assert "Capítulo 1" in out


def test_feature_detect_toc_finds_both(tmp_path) -> None:
    ncx = tmp_path / "toc.ncx"
    ncx.write_bytes(SAMPLE_NCX)
    nav = tmp_path / "nav.xhtml"
    nav.write_bytes(SAMPLE_NAVDOC)
    ncx_files, nav_files = feature_detect_toc(tmp_path)
    assert ncx_files == [ncx]
    assert nav_files == [nav]


def test_feature_detect_toc_no_toc(tmp_path) -> None:
    (tmp_path / "ch1.xhtml").write_bytes(b"<html><body><p>hi</p></body></html>")
    ncx_files, nav_files = feature_detect_toc(tmp_path)
    assert ncx_files == []
    assert nav_files == []
