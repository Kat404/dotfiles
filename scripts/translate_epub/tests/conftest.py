"""Shared pytest fixtures (REQ-070, T23).

`tests/fixtures/sample.epub` is the committed binary. To regenerate:
  uv run --with pytest --with pytest-asyncio -- pytest -c 'from conftest import build_sample_epub_bytes; open("tests/fixtures/sample.epub","wb").write(build_sample_epub_bytes())'
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest

SAMPLE_EPUB_PATH = Path(__file__).parent / "fixtures" / "sample.epub"


@pytest.fixture(scope="session")
def sample_epub_bytes() -> bytes:
    return SAMPLE_EPUB_PATH.read_bytes()


@pytest.fixture
def sample_epub_path(tmp_path: Path, sample_epub_bytes: bytes) -> Path:
    p = tmp_path / "sample.epub"
    p.write_bytes(sample_epub_bytes)
    return p


@pytest.fixture
def stub_profile() -> dict[str, Any]:
    return {
        "title": "Sample Book",
        "author": "Test Author",
        "target_language": "Español",
        "tone_and_style": "Literario neutro",
        "synopsis_translated": "Descripción traducida al español.",
        "characters": [{"name": "Narrador", "gender": "Hombre", "role": "Narrador"}],
        "never_translate_names": ["Test Author"],
        "chapter_titles": {},
        "keywords": [],
        "glossary": {},
    }


@pytest.fixture
def llm_stub():
    """MagicMock OpenAI client echoing inputs wrapped in <lang>."""
    from unittest.mock import MagicMock

    client = MagicMock()

    def _fake(*_a, **kw):
        content = kw["messages"][1]["content"]
        items = json.loads(content[content.rfind("[\n") :])
        out = [{"id": it["id"], "html": f"<lang>{it['id']}</lang>"} for it in items]
        return MagicMock(
            choices=[MagicMock(message=MagicMock(content=json.dumps({"translations": out})))]
        )

    client.chat.completions.create.side_effect = _fake
    return client
