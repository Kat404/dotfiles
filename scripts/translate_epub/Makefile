# =============================================================================
# Makefile — libros / rewrite-translate-epub
# =============================================================================
# No uv sync required: all tooling comes via PEP 723 + uv run --with.
# Targets: lint, format, typecheck, test, all

.PHONY: lint format typecheck test all

lint:
	uv run --with ruff -- ruff check translate_epub_ai.py scripts/

format:
	uv run --with ruff -- ruff format translate_epub_ai.py scripts/

typecheck:
	@if [ ! -d .venv-ty ]; then \
		uv venv .venv-ty --python 3.14 && \
		uv pip install --python .venv-ty/bin/python beautifulsoup4 lxml openai blake3 ruff ty; \
	fi
	.venv-ty/bin/ty check --python .venv-ty translate_epub_ai.py scripts/

test:
	uv run --with pytest --with pytest-asyncio \
		--with beautifulsoup4 --with lxml --with blake3 --with openai \
		-- pytest tests/ || \
		[ $$? -eq 5 ]  # exit 5 = no tests collected; acceptable pre-batch-2

all: lint typecheck test
