#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "beautifulsoup4",
#   "lxml",
#   "openai",
#   "blake3>=1.0.9,<2.0",
# ]
# ///

"""
================================================================================
UNIVERSAL AI EPUB LITERARY TRANSLATOR & ENGINE (OpenAI & MiniMax Compatible)
================================================================================
Motor universal y agnóstico de traducción literaria y preservación estructural
de libros EPUB. Diseñado para cualquier modelo LLM compatible con OpenAI API
(MiniMax, OpenAI, OpenRouter, Anthropic Proxy, Ollama, vLLM, DeepSeek).

Características Principales:
1. Universal & Agnóstico: Auto-descubrimiento del spine y OPF (Dublin Core).
2. Auto-Perfilado con IA (--generate-profile): Extrae metadatos, sinopsis y
   genera automáticamente la ficha de personajes, géneros y nombres intocables.
3. Checkpoints Deterministas BLAKE3: Aislados por libro
   (<input_dir>/.translate_epub/<blake3[:16]>/checkpoint.json). Cache + state.
4. Adaptive Batching: Si un lote falla, se subdivide recursivamente a nivel de párrafo.
5. Sanitización XML en Tiempo Real: Evita atributos rotos y malformaciones.
6. Traducción de Metadatos: Localiza dc:title, dc:description y TOC (NCX/Nav).
7. BLAKE3 nativo: sin fallbacks SHA-256. Fresh start automático si el state
   dir no existe. No se necesita --no-resume: el cache ES la señal de resume.

Uso:
  # Inspeccionar metadatos de cualquier EPUB:
  uv run translate_epub_ai.py --input "Libro.epub" --inspect

  # Generar automáticamente la ficha literaria del libro:
  uv run translate_epub_ai.py --input "Libro.epub" --generate-profile

  # Traducir el libro completo (fresh start si no hay state previo):
  uv run translate_epub_ai.py --input "Libro.epub"

  # Probar conectividad con el modelo configurado:
  uv run translate_epub_ai.py --test
================================================================================
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
import zipfile
from collections import deque
from pathlib import Path
from typing import Any, TypedDict
from urllib.parse import unquote

from blake3 import blake3
from bs4 import BeautifulSoup, Tag
from openai import OpenAI, OpenAIError

# -----------------------------------------------------------------------------
# CONFIGURACIÓN PREDETERMINADA DEL PROVEEDOR LLM
# -----------------------------------------------------------------------------
DEFAULT_BASE_URL: str = os.environ.get(
    "AI_BASE_URL", os.environ.get("MINIMAX_BASE_URL", "https://api.minimax.io/v1")
)
DEFAULT_MODEL: str = os.environ.get("AI_MODEL", os.environ.get("MINIMAX_MODEL", "MiniMax-M3"))


def resolve_api_key(cli_value: str | None) -> str:
    """Resolve API key from CLI flag or AI_API_KEY env. SystemExit(1) if neither."""
    key = cli_value or os.environ.get("AI_API_KEY")
    if not key:
        sys.stderr.write(
            "ERROR: Missing API credentials.\n"
            "  Set the environment variable:  export AI_API_KEY=...\n"
            "  Or pass the CLI flag:          --api-key <your-key>\n"
        )
        sys.exit(1)
    return key


# -----------------------------------------------------------------------------
# TIPADO ESTRUCTURADO (PEP 589 / PEP 604)
# -----------------------------------------------------------------------------
class Character(TypedDict):
    name: str
    gender: str
    role: str


class BookProfile(TypedDict, total=False):
    title: str
    title_translated: str
    author: str
    target_language: str
    tone_and_style: str
    synopsis_translated: str
    characters: list[Character]
    never_translate_names: list[str]
    chapter_titles: dict[str, str]
    keywords: list[str]
    glossary: dict[str, str]


class BatchItem(TypedDict, total=False):
    id: int
    html: str
    cache_key: str
    dom_element: Any
    translated_html: str


# Dublin Core namespaces para parsing OPF
NS_MAP = {
    "opf": "http://www.idpf.org/2007/opf",
    "dc": "http://purl.org/dc/elements/1.1/",
    "ncx": "http://www.daisy.org/z3986/2005/ncx/",
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
}

ENGLISH_INDICATORS = {
    "the",
    "and",
    "with",
    "from",
    "they",
    "their",
    "were",
    "which",
    "would",
    "could",
    "said",
    "about",
    "after",
    "before",
    "between",
    "through",
    "where",
    "there",
    "what",
    "when",
}

SPANISH_INDICATORS = {
    "el",
    "la",
    "los",
    "las",
    "un",
    "una",
    "unos",
    "unas",
    "y",
    "de",
    "en",
    "que",
    "por",
    "con",
    "para",
    "estaba",
    "dijo",
    "había",
    "pero",
    "como",
    "más",
    "sus",
    "del",
}


# -----------------------------------------------------------------------------
# CLIENTE LLM Y EXTRACCIÓN ROBUSTA
# -----------------------------------------------------------------------------
def get_client(api_key: str | None = None, base_url: str | None = None) -> OpenAI:
    """Build OpenAI client. `api_key` MUST be a non-empty string (resolved upstream)."""
    if not api_key:
        raise ValueError("api_key is required; call resolve_api_key() first")
    url = base_url or DEFAULT_BASE_URL
    return OpenAI(api_key=api_key, base_url=url)


# -----------------------------------------------------------------------------
# STATE ROOT RESOLUTION (REQ-010, REQ-011)
# -----------------------------------------------------------------------------
def resolve_state_dir(
    input_path: Path | None,
    override: str | os.PathLike[str] | None,
    env_value: str | None,
) -> Path:
    """4-tier priority: --state-dir > TRANSLATE_EPUB_STATE_DIR > <input>/.translate_epub/ > XDG.

    Empty strings count as absent.
    """
    if override:
        s = str(override).strip()
        if s:
            return Path(s).expanduser().resolve()
    if env_value:
        s = str(env_value).strip()
        if s:
            return Path(s).expanduser().resolve()
    if input_path is not None:
        return (input_path.parent / ".translate_epub").resolve()
    xdg = os.environ.get("XDG_DATA_HOME", "").strip()
    base = Path(xdg).expanduser() if xdg else Path.home() / ".local" / "share"
    return (base / "translate_epub_ai").resolve()


def book_state_paths(state_root: Path, book_hash: str) -> dict[str, Path]:
    """Return the canonical paths under <state_root>/<book_hash>/."""
    book_dir = state_root / book_hash
    return {
        "book_dir": book_dir,
        "workspace": book_dir / "workspace",
        "profile": book_dir / "profile.json",
        "checkpoint": book_dir / "checkpoint.json",
        "audit": book_dir / "audit.log",
    }


# -----------------------------------------------------------------------------
# HASHING (REQ-030, REQ-031) — BLAKE3, 16-hex truncation
# -----------------------------------------------------------------------------
def compute_file_sha(path: Path) -> str:
    """BLAKE3 of raw file bytes, truncated to 16 hex chars. Same input → same hash."""
    return blake3(path.read_bytes()).hexdigest()[:16]


def compute_paragraph_hash(html: str) -> str:
    """BLAKE3 of UTF-8 encoded HTML, truncated to 16 hex chars."""
    return blake3(html.encode("utf-8")).hexdigest()[:16]


def build_checkpoint_key(filename: str, p_hash: str) -> str:
    """Compose the cache key. Format kept for downstream parity: filename::hash."""
    return f"{filename}::{p_hash}"


# -----------------------------------------------------------------------------
# ATOMIC WRITE (REQ-022, REQ-023)
# -----------------------------------------------------------------------------
def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    """Write JSON atomically: tmp + fsync + Path.replace. Single-process only.

    ponytail: no file locking — concurrent writers may lose updates. Acceptable
    here because the script is one process at a time (REQ-021 single-process MVP).
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    except OSError:
        if tmp.exists():
            tmp.unlink()
        raise


# -----------------------------------------------------------------------------
# LEGACY SHA-256 READER — REMOVED (BLAKE3-native only)
# -----------------------------------------------------------------------------
# The script is now BLAKE3-only. Users with legacy SHA-256 caches from earlier
# versions should run `scripts/migrate_checkpoints.py` (one-shot tool) to
# convert their caches to BLAKE3 before resuming. After that, the script
# resumes BLAKE3 state automatically.


def extract_json_from_response(raw_text: str) -> str:
    """Extrae bloques JSON válidos eliminando razonamientos (<think>) y delimitadores markdown."""
    text = raw_text.strip()
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.DOTALL).strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\n", "", text)
        text = re.sub(r"\n```$", "", text).strip()

    # Búsqueda específica de claves conocidas
    match_trans = re.search(r"\{[\s\S]*\"translations\"[\s\S]*\}", text)
    if match_trans:
        return match_trans.group(0)

    # Búsqueda genérica de cualquier objeto {...}
    match_any = re.search(r"(\{[\s\S]*\})", text)
    if match_any:
        return match_any.group(1)

    return text


def sanitize_html_fragment(fragment: str | None) -> str:
    """Sanitize an LLM-returned HTML fragment. Never raises.

    Handles 6 cases (REQ-061): valid, unbalanced quotes, BS4 fallback,
    empty string, None, broken markup. Returns a string (possibly empty).
    """
    if fragment is None:
        return ""
    fixed = fragment.strip()
    if not fixed:
        return ""
    fixed = re.sub(r'class="([^">]+)",\s*', r'class="\1">', fixed)
    fixed = re.sub(r'id="([^">]+)",\s*', r'id="\1">', fixed)
    try:
        wrapped = f"<root>{fixed}</root>"
        ET.fromstring(wrapped)
        return fixed
    except ET.ParseError:
        soup = BeautifulSoup(fixed, "html.parser")
        return "".join(str(c) for c in soup.contents) if soup.contents else ""


def is_text_likely_untranslated(text: str) -> bool:
    words = [re.sub(r"[^\w]", "", w.lower()) for w in text.split()]
    if len(words) < 8:
        return False
    eng_count = sum(1 for w in words if w in ENGLISH_INDICATORS)
    spa_count = sum(1 for w in words if w in SPANISH_INDICATORS)
    return eng_count >= 3 and eng_count > spa_count


# -----------------------------------------------------------------------------
# INSPECCIÓN UNIVERSAL DE CONTENEDOR EPUB & METADATOS (OPF & SPINE)
# -----------------------------------------------------------------------------
class EPUBInspector:
    def __init__(self, epub_path: Path):
        self.epub_path = epub_path
        if not self.epub_path.exists():
            raise FileNotFoundError(f"No se encontró el archivo: {epub_path}")
        self.file_sha = compute_file_sha(self.epub_path)

    def extract_info(self) -> dict[str, Any]:
        """Lee el container.xml, ubica el .opf y analiza metadatos y orden de lectura del spine."""
        with zipfile.ZipFile(self.epub_path, "r") as z:
            # 1. Localizar OPF en META-INF/container.xml
            try:
                container_xml = z.read("META-INF/container.xml")
                root = ET.fromstring(container_xml)
                rootfile = root.find(".//{urn:oasis:names:tc:opendocument:xmlns:container}rootfile")
                if rootfile is None or "full-path" not in rootfile.attrib:
                    raise ValueError("container.xml no especifica full-path a content.opf")
                opf_rel_path = rootfile.attrib["full-path"]
            except (KeyError, ValueError, ET.ParseError) as exc:
                # Fallback: buscar cualquier archivo .opf en el zip
                opf_candidates = [f for f in z.namelist() if f.endswith(".opf")]
                if not opf_candidates:
                    raise FileNotFoundError(
                        "No se encontró archivo .opf en el contenedor EPUB."
                    ) from exc
                opf_rel_path = opf_candidates[0]

            opf_dir = str(Path(opf_rel_path).parent)
            if opf_dir == ".":
                opf_dir = ""

            # 2. Parsear el archivo OPF
            opf_content = z.read(opf_rel_path)
            opf_root = ET.fromstring(opf_content)

            # Extraer metadatos Dublin Core
            metadata = {}
            for tag in [
                "title",
                "creator",
                "description",
                "language",
                "publisher",
                "date",
            ]:
                node = opf_root.find(f".//{{{NS_MAP['dc']}}}{tag}")
                metadata[tag] = node.text.strip() if (node is not None and node.text) else ""

            # Extraer manifiesto (id -> href)
            manifest = {}
            for item in opf_root.findall(f".//{{{NS_MAP['opf']}}}item"):
                item_id = item.attrib.get("id")
                href = unquote(item.attrib.get("href", ""))
                media_type = item.attrib.get("media-type", "")
                if item_id and href:
                    # Construir ruta completa dentro del zip
                    full_href = f"{opf_dir}/{href}".lstrip("/") if opf_dir else href
                    manifest[item_id] = {"href": full_href, "media_type": media_type}

            # Extraer spine (orden estricto de lectura de los XHTML)
            spine_files: list[str] = []
            for itemref in opf_root.findall(f".//{{{NS_MAP['opf']}}}itemref"):
                idref = itemref.attrib.get("idref")
                if idref in manifest:
                    item_info = manifest[idref]
                    if item_info["media_type"] in [
                        "application/xhtml+xml",
                        "text/html",
                    ]:
                        spine_files.append(item_info["href"])

            # 3. Muestrear contenido de los primeros capítulos para el perfilado
            sample_paragraphs: list[str] = []
            total_paragraphs = 0
            for doc in spine_files:
                if doc in z.namelist():
                    doc_soup = BeautifulSoup(
                        z.read(doc).decode("utf-8", errors="ignore"), "html.parser"
                    )
                    body = doc_soup.find("body")
                    if body:
                        p_tags = [
                            p.get_text().strip() for p in body.find_all("p") if p.get_text().strip()
                        ]
                        total_paragraphs += len(p_tags)
                        if len(sample_paragraphs) < 30:
                            sample_paragraphs.extend(p_tags[:10])

            return {
                "opf_path": opf_rel_path,
                "opf_dir": opf_dir,
                "file_sha": self.file_sha,
                "metadata": metadata,
                "spine_files": spine_files,
                "total_paragraphs": total_paragraphs,
                "sample_text": sample_paragraphs[:25],
            }


# -----------------------------------------------------------------------------
# AUTO-GENERADOR DE PERFIL LITERARIO VÍA LLM
# -----------------------------------------------------------------------------
def generate_book_profile(
    client: OpenAI, model: str, info: dict[str, Any], output_json_path: Path
) -> BookProfile:
    """Analyze synopsis + samples with LLM to produce the BookProfile TypedDict."""
    meta = info["metadata"]
    title = meta.get("title", "Obra Desconocida")
    author = meta.get("creator", "Autor Desconocido")
    desc = meta.get("description", "Sin descripción previa.")
    sample = "\n---\n".join(info.get("sample_text", []))

    print(f"\nGenerando perfil literario con IA para: '{title}' ({author})...")

    prompt = (
        "Eres un editor literario y director de traducción. Analiza la siguiente obra "
        "en inglés y genera su Ficha Literaria para su posterior traducción al español.\n\n"
        "METADATOS:\n"
        f"- Título original: {title}\n"
        f"- Autor: {author}\n"
        f"- Sinopsis / Descripción:\n{desc}\n\n"
        f"MUESTRA DE TEXTO NARRATIVO:\n{sample}\n\n"
        "INSTRUCCIONES:\n"
        "Devuelve EXCLUSIVAMENTE un JSON con la siguiente estructura exacta:\n"
        "{\n"
        f'  "title": "{title}",\n'
        '  "title_translated": "Traducción fiel del título al español",\n'
        f'  "author": "{author}",\n'
        '  "target_language": "Español neutro / literario de alta fidelidad",\n'
        '  "tone_and_style": "Descripción del tono (ej. terror psicológico, '
        'fantasía épica, ensayo académico) y tratamiento de diálogos",\n'
        '  "synopsis_translated": "Traducción fidedigna y profesional de la sinopsis",\n'
        '  "characters": [\n'
        '    {"name": "NombrePersonaje", "gender": "Hombre (él) | Mujer (ella) | '
        'No binario", "role": "Rol breve en la trama"}\n'
        "  ],\n"
        '  "never_translate_names": ["Lista", "de", "nombres", "propios", "lugares", '
        '"marcas", "que", "deben", "permanecer", "intactos"],\n'
        '  "chapter_titles": {}\n'
        "}\n"
    )

    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": "Eres un asistente estructurado de análisis literario. "
                "Devuelve solo JSON válido.",
            },
            {"role": "user", "content": prompt},
        ],
        temperature=0.2,
        max_tokens=4000,
    )
    raw = response.choices[0].message.content or ""
    clean = extract_json_from_response(raw)
    profile: BookProfile = json.loads(clean)

    # Guardar en disco (atomic, REQ-022)
    atomic_write_json(output_json_path, dict(profile))

    print(f"[OK] Ficha literaria guardada exitosamente en: {output_json_path}")
    return profile


# -----------------------------------------------------------------------------
# MOTOR DE TRADUCCIÓN CON ADAPTIVE BATCHING Y CHECKPOINTS DETERMINISTAS
# -----------------------------------------------------------------------------
class UniversalBatchTranslator:
    def __init__(
        self,
        client: OpenAI,
        model: str,
        profile: BookProfile,
        checkpoint_file: Path,
        context_window: int = 3,
    ) -> None:
        self.client = client
        self.model = model
        self.profile = profile
        self.checkpoint_file = checkpoint_file
        self.context_window = max(0, context_window)
        self.recent_translations: deque[str] = deque(maxlen=self.context_window)
        self._current_spine: str | None = None
        self.system_prompt = self._build_system_prompt()
        # BLAKE3-only cache; if the state dir is fresh, cache stays empty and
        # translate_batch starts from scratch automatically.
        self.cache = self._load_checkpoint()

    def reset_context(self, spine_filename: str) -> None:
        """Reset sliding-window deque when a new spine file begins (REQ-040)."""
        if self._current_spine != spine_filename:
            self.recent_translations.clear()
            self._current_spine = spine_filename

    def _build_context_note(self) -> str:
        """Format <context_note> from recent translations, max 200 chars each."""
        if not self.recent_translations:
            return ""
        items = list(self.recent_translations)[::-1]  # most recent first
        lines = [
            "<context_note>",
            "Previously translated in this chapter (most recent first):",
        ]
        for i, txt in enumerate(items, 1):
            plain = BeautifulSoup(txt, "html.parser").get_text().strip()
            lines.append(f'{i}. "{plain[:200]}"')
        lines.append("</context_note>")
        return "\n".join(lines)

    def _build_glossary_block(self) -> str:
        """Format <glossary> block from current glossary map (REQ-041)."""
        glossary = self.profile.get("glossary") or {}
        if not glossary:
            return ""
        lines = ["<glossary>"]
        for src, dst in sorted(glossary.items()):
            lines.append(f"- {src} → {dst}")
        lines.append("</glossary>")
        return "\n".join(lines)

    def _maybe_grow_glossary(self, original_html: str, translated_html: str) -> bool:
        """Extract capitalized proper nouns from translation; if they match known English
        names, append new glossary entries. Returns True if anything was added."""
        glossary = self.profile.setdefault("glossary", {})
        if not glossary:
            self.profile["glossary"] = glossary
        known_english = {c.get("name", "") for c in self.profile.get("characters", [])}
        known_english.update(self.profile.get("never_translate_names", []) or [])
        known_english = {n for n in known_english if n}
        if not known_english:
            return False
        translated_plain = BeautifulSoup(translated_html, "html.parser").get_text()
        # Match capitalized word runs in translation (e.g., "Harry Potter", "Jon").
        candidates = set(
            re.findall(
                r"\b([A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÑáéíóúñ]{1,}(?:\s+[A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÑáéíóúñ]{1,})*)\b",
                translated_plain,
            )
        )
        # Look for English names appearing in the ORIGINAL html.
        original_plain = BeautifulSoup(original_html, "html.parser").get_text()
        original_names = {n for n in known_english if n in original_plain}
        added = False
        for english in original_names:
            for cand in candidates:
                if cand.lower() == english.lower() or english.lower() in cand.lower():
                    if glossary.get(english) != cand:
                        glossary[english] = cand
                        added = True
        return added

    def _build_system_prompt(self) -> str:
        chars_desc = "\n".join(
            [
                f"- {c['name']}: {c['gender']} ({c.get('role', '')})"
                for c in self.profile.get("characters", [])
            ]
        )
        never_trans = ", ".join(self.profile.get("never_translate_names", []) or [])
        glossary_snapshot = self._build_glossary_block()
        # REQ-042: keywords deduped + lowercased.
        keywords = sorted({k.lower() for k in (self.profile.get("keywords") or []) if k})

        # REQ-043: 7 ordered sections, each omitted when data absent.
        sections: list[str] = []
        sections.append(
            "Eres un traductor literario profesional de máxima categoría, especializado en "
            "traducción editorial de libros al español."
        )
        sections.append(
            "CONTEXTO DE LA NOVELA:\n"
            f"- Obra: {self.profile.get('title', '')} de {self.profile.get('author', '')}\n"
            f"- Tono y registro: {self.profile.get('tone_and_style', 'Literario')}"
        )
        if self.profile.get("synopsis_translated"):
            sections.append(f"SINOPSIS:\n{self.profile['synopsis_translated']}")
        if chars_desc:
            sections.append(
                f"GUÍA DE GÉNERO Y PERSONAJES (CRÍTICO):\n{chars_desc}\n"
                "* IMPORTANTE: Respeta estrictamente la concordancia de género."
            )
        if glossary_snapshot:
            sections.append(f"GLOSARIO ACTUAL (REUTILIZA EXACTAMENTE):\n{glossary_snapshot}")
        if keywords:
            sections.append(
                "ÉNFASIS DE VOCABULARIO (mantén traducciones consistentes):\n" + ", ".join(keywords)
            )
        sections.append(
            "REGLAS DE FORMATO Y ENTREGA:\n"
            "1. Recibirás un objeto JSON con una lista de elementos: "
            '`[{"id": 0, "html": "...<p>text</p>..."}, ...]`.\n'
            '2. Devuelve EXCLUSIVAMENTE un JSON válido con la clave `"translations"` '
            "manteniendo los mismos IDs.\n"
            "3. MANTÉN INTACTAS las etiquetas HTML internas y sus atributos exactos. "
            "Solo traduce el texto humano.\n"
            "4. No agregues explicaciones ni texto fuera del JSON."
        )
        if never_trans:
            sections.append(f"NOMBRES PROPIOS INTOCABLES (NO TRADUCIR): [{never_trans}]")

        return "\n\n".join(sections)

    def _load_checkpoint(self) -> dict[str, str]:
        """Load the BLAKE3 cache from <state_root>/<book_hash>/checkpoint.json.

        Returns an empty dict when the file is absent or unreadable — that is
        the fresh-start signal: translate_batch will simply translate every
        paragraph it sees and write the cache as it goes. There is no
        `--resume` / `--no-resume` flag; the cache IS the resume signal.
        """
        cache: dict[str, str] = {}
        if self.checkpoint_file.exists():
            try:
                with open(self.checkpoint_file, encoding="utf-8") as f:
                    cache = json.load(f)
            except (json.JSONDecodeError, OSError) as e:
                print(f"[WARN] Error al cargar checkpoint: {e}. Creando nuevo.")
        return cache

    def _save_checkpoint(self) -> None:
        try:
            atomic_write_json(self.checkpoint_file, self.cache)
        except OSError as e:
            print(f"[WARN] Error al guardar checkpoint: {e}")

    def purge_invalid_entries(self) -> int:
        """Audita y purga entradas con XML roto o en inglés."""
        purged = 0
        keys_to_remove = []
        for key, trans_html in self.cache.items():
            soup = BeautifulSoup(trans_html, "html.parser")
            txt = soup.get_text().strip()
            if is_text_likely_untranslated(txt):
                keys_to_remove.append(key)
                continue
            try:
                wrapped = f"<root>{trans_html}</root>"
                ET.fromstring(wrapped)
            except ET.ParseError:
                keys_to_remove.append(key)

        for key in keys_to_remove:
            del self.cache[key]
            purged += 1

        if purged > 0:
            self._save_checkpoint()
            print(f"[CHECKPOINT] Se purgaron {purged} entradas defectuosas.")
        else:
            print("[CHECKPOINT] El checkpoint está 100% limpio y válido.")
        return purged

    def _call_llm(self, items_to_translate: list[BatchItem], context_note: str) -> dict[int, str]:
        payload = [{"id": item["id"], "html": item["html"]} for item in items_to_translate]
        # REQ-040: sliding-window <context_note> injected as actual content (not label).
        ctx_block = self._build_context_note()
        # REQ-041: glossary snapshot injected in user message.
        glossary_block = self._build_glossary_block()
        user_message = ""
        if ctx_block:
            user_message += ctx_block + "\n\n"
        if glossary_block:
            user_message += glossary_block + "\n\n"
        if context_note:
            user_message += f"[CONTEXTO DE ESCENA: {context_note}]\n\n"
        user_message += (
            "Traduce los siguientes elementos al español manteniendo las "
            f"etiquetas HTML exactas:\n{json.dumps(payload, ensure_ascii=False, indent=2)}"
        )

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": user_message},
            ],
            temperature=0.2,
            max_tokens=8192,
        )
        raw_out = response.choices[0].message.content or ""
        clean_json = extract_json_from_response(raw_out)
        parsed = json.loads(clean_json)
        translations: dict[int, str] = {}
        for t in parsed.get("translations", []):
            sanitized = sanitize_html_fragment(t.get("html", ""))
            translations[int(t["id"])] = sanitized
        return translations

    def _observe_translations(self, items: list[BatchItem]) -> None:
        """Push translated_html of items onto the sliding-window deque (most-recent at right)."""
        if self.context_window <= 0:
            return
        for item in items:
            trans = item.get("translated_html") or item["html"]
            self.recent_translations.append(trans)

    def translate_batch(
        self, batch_items: list[BatchItem], context_note: str = ""
    ) -> list[BatchItem]:
        """Traduce con Adaptive Batching determinista (BLAKE3 cache only)."""
        pending_items: list[BatchItem] = []
        for item in batch_items:
            if item["cache_key"] in self.cache:
                item["translated_html"] = self.cache[item["cache_key"]]
            else:
                pending_items.append(item)

        if not pending_items:
            # Cache-only path: still observe into the sliding window for consistency.
            self._observe_translations(batch_items)
            return batch_items

        max_retries = 2
        for attempt in range(1, max_retries + 1):
            try:
                translations = self._call_llm(pending_items, context_note)
                for item in pending_items:
                    iid = item["id"]
                    if iid in translations:
                        trans_html = translations[iid]
                        item["translated_html"] = trans_html
                        self.cache[item["cache_key"]] = trans_html
                    else:
                        item["translated_html"] = item["html"]

                self._save_checkpoint()
                # REQ-041: grow glossary from successful translations.
                for item in pending_items:
                    self._maybe_grow_glossary(item["html"], item.get("translated_html") or "")
                self._observe_translations(pending_items)
                return batch_items

            except (OpenAIError, json.JSONDecodeError, KeyError, ValueError) as e:
                print(
                    f"[WARN] Reintento {attempt}/{max_retries} ({len(pending_items)} párrafos): {e}"
                )
                time.sleep(2 * attempt)

        # Adaptive subdivision
        if len(pending_items) > 1:
            mid = len(pending_items) // 2
            print(
                f"[ADAPTIVE BATCH] Subdividiendo {len(pending_items)} párrafos en "
                f"2 sublotes ({mid} y {len(pending_items) - mid})..."
            )
            self.translate_batch(pending_items[:mid], context_note=f"{context_note} (sub 1)")
            self.translate_batch(pending_items[mid:], context_note=f"{context_note} (sub 2)")
            return batch_items

        pending_items[0]["translated_html"] = pending_items[0]["html"]
        self._observe_translations(pending_items)
        return batch_items

    # -----------------------------------------------------------------------------
    # PROCESAMIENTO GENERAL DEL EPUB
    # -----------------------------------------------------------------------------


def process_universal_epub(
    input_path: Path,
    output_path: Path,
    translator: UniversalBatchTranslator,
    inspector_info: dict[str, Any],
    work_dir: Path,
    batch_size: int = 6,
    single_batch_only: int | None = None,
) -> bool:
    """Translate spine + TOC. Returns True if any TOC warning was emitted.

    The caller promotes this to exit 1 when --strict-toc is on.
    """
    print(f"\nIniciando procesamiento de: {input_path}")
    print(f"Destino: {output_path}")
    print(f"Workspace: {work_dir}")

    container_marker = work_dir / "META-INF" / "container.xml"
    if work_dir.exists() and container_marker.exists():
        print("[RESUME] Workspace existente detectado; reusando (sin re-extracción).")
        # ponytail: extraction skipped; cache hits also avoid LLM via translate_batch
    else:
        work_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(input_path, "r") as z:
            z.extractall(work_dir)

    spine_files: list[str] = inspector_info["spine_files"]
    print(f"Documentos en spine para traducir: {len(spine_files)}")

    total_batches_processed = 0

    for rel_doc in spine_files:
        doc_path = work_dir / rel_doc
        if not doc_path.exists():
            continue

        filename = doc_path.name
        print(f"\n--- Procesando: {rel_doc} ---")
        translator.reset_context(filename)

        with open(doc_path, encoding="utf-8", errors="ignore") as f:
            raw_html = f.read()

        soup = BeautifulSoup(raw_html, "html.parser")
        body = soup.find("body")
        if not body:
            continue

        paragraphs = [p for p in body.find_all("p") if p.get_text().strip()]
        print(f"  Párrafos encontrados: {len(paragraphs)}")
        if not paragraphs:
            continue

        batches = [paragraphs[i : i + batch_size] for i in range(0, len(paragraphs), batch_size)]

        for b_idx, batch in enumerate(batches):
            total_batches_processed += 1
            if single_batch_only and total_batches_processed > single_batch_only:
                print(f"[INFO] Modo ensayo finalizado tras {single_batch_only} lote(s).")
                break

            batch_items: list[BatchItem] = []
            for idx, p in enumerate(batch):
                p_html = "".join(str(c) for c in p.contents)
                p_sha = compute_paragraph_hash(p_html)
                cache_key = build_checkpoint_key(filename, p_sha)
                batch_items.append(
                    {
                        "id": idx,
                        "html": p_html,
                        "cache_key": cache_key,
                        "dom_element": p,
                    }
                )

            all_cached = all(item["cache_key"] in translator.cache for item in batch_items)
            if all_cached:
                print(
                    f"  Lote {b_idx + 1}/{len(batches)} ({len(batch)} párrafos) "
                    "-> [RECUPERADO DE CHECKPOINT]"
                )
            else:
                print(f"  Traduciendo lote {b_idx + 1}/{len(batches)} ({len(batch)} párrafos)...")

            translated_items = translator.translate_batch(
                batch_items, context_note=f"Archivo {filename}, bloque {b_idx + 1}"
            )

            for item in translated_items:
                dom_el = item["dom_element"]
                trans_html = item.get("translated_html", item["html"])
                cache_key = item["cache_key"]
                # REQ-060: capture <p> attributes BEFORE clear() so we can re-apply.
                preserved_attrs = {
                    k: v
                    for k, v in dom_el.attrs.items()
                    if k in ("class", "id") or k.startswith("data-") or k == "epub:type"
                }
                # REQ-062: empty / whitespace-only translation → keep original.
                stripped = BeautifulSoup(trans_html, "html.parser").get_text().strip()
                if not stripped:
                    print(
                        f"  [WARN] empty translation for {cache_key}; using original",
                        file=sys.stderr,
                    )
                    continue
                try:
                    new_contents = BeautifulSoup(trans_html, "html.parser")
                    dom_el.clear()
                    for child in list(new_contents.contents):
                        # Avoid <p><p>...</p></p> when LLM wraps translation in <p>
                        # and the original element is also <p> (BS4 nesting rule, req).
                        if dom_el.name == "p" and isinstance(child, Tag) and child.name == "p":
                            for grandchild in list(child.contents):
                                dom_el.append(grandchild)
                            child.extract()
                        else:
                            dom_el.append(child)
                    # Re-apply attributes (defense in depth, REQ-060).
                    for k, v in preserved_attrs.items():
                        if k not in dom_el.attrs:
                            dom_el.attrs[k] = v
                except (ValueError, TypeError, ET.ParseError) as e:
                    print(f"  [ERROR] DOM Injection {cache_key}: {e}")

            if single_batch_only and total_batches_processed >= single_batch_only:
                break

        with open(doc_path, "w", encoding="utf-8") as f:
            f.write(str(soup))

        if single_batch_only and total_batches_processed >= single_batch_only:
            break

    # --- TOC phase (REQ-050..054) -----------------------------------------
    ncx_files, nav_files = feature_detect_toc(work_dir)
    if ncx_files and nav_files:
        print(f"[INFO] dual TOC detected: {len(ncx_files)} NCX + {len(nav_files)} NavDoc")
    if not ncx_files and not nav_files:
        print(f"[WARN] no TOC found in {input_path.name}")
    toc_warned = apply_toc_translations(
        work_dir, ncx_files, nav_files, translator, translator.profile, batch_size
    )

    # Actualizar metadatos y descripción en el archivo OPF
    opf_file = work_dir / inspector_info["opf_path"]
    if opf_file.exists():
        try:
            with open(opf_file, encoding="utf-8") as f:
                opf_raw = f.read()

            # 1. Actualizar dc:language a es
            opf_raw = re.sub(
                r"<dc:language>[^<]+</dc:language>",
                "<dc:language>es</dc:language>",
                opf_raw,
            )

            # 2. Actualizar dc:description si está traducida
            synopsis_es = translator.profile.get("synopsis_translated", "")
            if synopsis_es and "<dc:description>" in opf_raw:
                opf_raw = re.sub(
                    r"<dc:description>[\s\S]*?</dc:description>",
                    f"<dc:description>{synopsis_es}</dc:description>",
                    opf_raw,
                )

            with open(opf_file, "w", encoding="utf-8") as f:
                f.write(opf_raw)
            print("\n[OK] Metadatos actualizados en content.opf (lenguaje y sinopsis)")
        except (OSError, re.error) as e:
            print(f"[WARN] No se pudo actualizar OPF: {e}")

    # Re-empaquetado estándar EPUB
    print(f"\nEmpaquetando nuevo EPUB en: {output_path}...")
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as out_zip:
        mimetype_path = work_dir / "mimetype"
        if mimetype_path.exists():
            out_zip.write(mimetype_path, "mimetype", compress_type=zipfile.ZIP_STORED)

        for file_path in work_dir.rglob("*"):
            if file_path.is_file() and file_path.name != "mimetype":
                rel = file_path.relative_to(work_dir)
                out_zip.write(file_path, str(rel))

    print(f"[COMPLETADO] Libro traducido generado exitosamente: {output_path}")
    return toc_warned


# -----------------------------------------------------------------------------
# TOC — NCX + NavDoc (REQ-050..054, T19..T22)
# -----------------------------------------------------------------------------
# region: toc


class TOCEntry(TypedDict, total=False):
    """A single TOC entry extracted from NCX <text> or NavDoc <a>."""

    id: int
    text: str
    dom_element: Any  # BS4 Tag (the <text> or <a> node)
    href: str  # navdoc only — preserved on write
    navpoint_id: str  # ncx only — preserved on write


def parse_ncx(content: bytes, soup: BeautifulSoup | None = None) -> list[TOCEntry]:
    """Parse <text> elements inside <navMap> of an NCX document.

    Defensive against malformed XML: returns [] when structure is absent
    (caller logs [WARN] malformed NCX).

    Pass an existing `soup` to mutate that tree in place (REQ-052: ensures
    disk-write reflects translations). Without `soup`, parses fresh bytes.
    """
    if soup is None:
        soup = BeautifulSoup(content, "xml")
    nav_map = soup.find("navMap")
    if nav_map is None:
        return []
    entries: list[TOCEntry] = []
    idx = 0
    for nav_point in nav_map.find_all("navPoint", recursive=True):
        text_tag = nav_point.find("text")
        if text_tag is None:
            continue
        text = text_tag.get_text().strip()
        if not text:
            continue
        entries.append(
            {
                "id": idx,
                "text": text,
                "dom_element": text_tag,
                "navpoint_id": str(nav_point.get("id", "")),
            }
        )
        idx += 1
    return entries


def parse_navdoc(content: bytes, soup: BeautifulSoup | None = None) -> list[TOCEntry]:
    """Parse <a> text inside <nav epub:type="toc"> of a nav.xhtml document.

    Outer <a href="..."> attributes are preserved on write.

    Pass an existing `soup` to mutate that tree in place (REQ-052: ensures
    disk-write reflects translations). Without `soup`, parses fresh bytes.
    """
    if soup is None:
        soup = BeautifulSoup(content, "xml")
    toc_nav = soup.find("nav", attrs={"epub:type": "toc"})
    if toc_nav is None:
        return []
    entries: list[TOCEntry] = []
    idx = 0
    for a in toc_nav.find_all("a"):
        text = a.get_text().strip()
        if not text:
            continue
        entries.append(
            {
                "id": idx,
                "text": text,
                "dom_element": a,
                "href": str(a.get("href", "")),
            }
        )
        idx += 1
    return entries


def feature_detect_toc(work_dir: Path) -> tuple[list[Path], list[Path]]:
    """Scan work_dir for TOC files by feature, not filename.

    Returns (ncx_files, nav_files). Each list contains full Paths.
    Files matching both features are classified as NCX (navMap wins).
    """
    ncx_files: list[Path] = []
    nav_files: list[Path] = []
    for ext in ("*.ncx", "*.xhtml", "*.html"):
        for path in work_dir.rglob(ext):
            try:
                blob = path.read_bytes()
            except OSError:
                continue
            if b"<navMap" in blob:
                ncx_files.append(path)
            elif b'epub:type="toc"' in blob or b"epub:type='toc'" in blob:
                nav_files.append(path)
    return ncx_files, nav_files


def _build_toc_batch_items(
    entries: list[TOCEntry],
    filename: str,
    soup_for_lookup: BeautifulSoup,
) -> list[BatchItem]:
    """Wrap parsed TOC entries into BatchItem shape for translate_batch."""
    items: list[BatchItem] = []
    for entry in entries:
        text = entry["text"]
        p_hash = compute_paragraph_hash(text)
        cache_key = build_checkpoint_key(filename, p_hash)
        items.append(
            {
                "id": entry["id"],
                "html": f'<p class="toc-entry">{text}</p>',
                "cache_key": cache_key,
                "dom_element": entry["dom_element"],
            }
        )
    return items


def _persist_toc_file(path: Path, soup: BeautifulSoup) -> None:
    """Write the modified BS4 tree back as bytes (preserves xml decl)."""
    path.write_bytes(str(soup).encode("utf-8"))


def apply_toc_translations(
    work_dir: Path,
    ncx_files: list[Path],
    nav_files: list[Path],
    translator: UniversalBatchTranslator,
    profile: BookProfile,
    batch_size: int = 6,
) -> bool:
    """Translate TOC entries via translate_batch. Returns True if any warning logged.

    Writes modified NCX + NavDoc files back to work_dir. Updates
    profile.chapter_titles in memory (caller persists profile.json).
    """
    warned = False
    chapter_titles: dict[str, str] = profile.setdefault("chapter_titles", {})

    # NCX files: one soup per file; modified in-place; write back at end.
    ncx_soups: dict[Path, BeautifulSoup] = {}
    for ncx_path in ncx_files:
        rel = ncx_path.relative_to(work_dir)
        try:
            content = ncx_path.read_bytes()
            soup = BeautifulSoup(content, "xml")
        except OSError as e:
            print(f"[WARN] malformed NCX: {rel} ({e})")
            warned = True
            continue
        entries = parse_ncx(content, soup=soup)
        if not entries:
            print(f"[WARN] malformed NCX: {rel}")
            warned = True
            continue
        items = _build_toc_batch_items(entries, "toc.ncx", soup)
        translator.reset_context(f"toc.ncx::{ncx_path.name}")
        translated = translator.translate_batch(items, context_note=f"NCX TOC {rel}")
        for item in translated:
            trans_html = item.get("translated_html") or item["html"]
            new_text = sanitize_html_fragment(trans_html)
            new_text = BeautifulSoup(new_text, "html.parser").get_text().strip()
            tag = item["dom_element"]
            orig_text = tag.get_text().strip()
            if new_text and orig_text:
                # No destructive overwrite — keep first successful translation.
                chapter_titles.setdefault(orig_text, new_text)
                tag.clear()
                tag.append(new_text)
        ncx_soups[ncx_path] = soup

    for ncx_path, soup in ncx_soups.items():
        try:
            _persist_toc_file(ncx_path, soup)
        except OSError as e:
            print(f"[WARN] cannot write NCX {ncx_path.relative_to(work_dir)}: {e}")
            warned = True

    # NavDoc files: same pattern, preserve href attributes.
    nav_soups: dict[Path, BeautifulSoup] = {}
    for nav_path in nav_files:
        rel = nav_path.relative_to(work_dir)
        try:
            content = nav_path.read_bytes()
            soup = BeautifulSoup(content, "xml")
        except OSError as e:
            print(f"[WARN] malformed navdoc: {rel} ({e})")
            warned = True
            continue
        entries = parse_navdoc(content, soup=soup)
        if not entries:
            print(f"[WARN] malformed navdoc: {rel}")
            warned = True
            continue
        items = _build_toc_batch_items(entries, "toc.nav", soup)
        translator.reset_context(f"toc.nav::{nav_path.name}")
        translated = translator.translate_batch(items, context_note=f"NavDoc TOC {rel}")
        for item in translated:
            trans_html = item.get("translated_html") or item["html"]
            new_text = sanitize_html_fragment(trans_html)
            new_text = BeautifulSoup(new_text, "html.parser").get_text().strip()
            tag = item["dom_element"]
            orig_text = tag.get_text().strip()
            href = tag.get("href", "")
            if new_text and orig_text:
                chapter_titles.setdefault(orig_text, new_text)
                tag.clear()
                if href:
                    tag["href"] = href
                tag.append(new_text)
        nav_soups[nav_path] = soup

    for nav_path, soup in nav_soups.items():
        try:
            _persist_toc_file(nav_path, soup)
        except OSError as e:
            print(f"[WARN] cannot write NavDoc {nav_path.relative_to(work_dir)}: {e}")
            warned = True

    return warned


# endregion: toc


# -----------------------------------------------------------------------------
# AUDITORÍA RÁPIDA INTEGRADA
# -----------------------------------------------------------------------------
def audit_epub(epub_path: Path) -> None:
    print("\n" + "=" * 60)
    print(f"AUDITANDO EPUB GENERADO: {epub_path}")
    print("=" * 60)

    if not epub_path.exists():
        print(f"[ERROR] El archivo {epub_path} no existe.")
        return

    with zipfile.ZipFile(epub_path, "r") as z:
        html_files = [f for f in z.namelist() if f.endswith((".html", ".xhtml"))]
        total_p = 0
        xml_errors = 0
        untranslated_warnings = 0

        for h in html_files:
            content = z.read(h).decode("utf-8", errors="ignore")
            try:
                ET.fromstring(content.encode("utf-8"))
            except ET.ParseError as e:
                print(f"[XML ERROR] {h}: {e}")
                xml_errors += 1

            soup = BeautifulSoup(content, "html.parser")
            paragraphs = soup.find_all("p")
            total_p += len(paragraphs)
            for p in paragraphs:
                txt = p.get_text().strip()
                if is_text_likely_untranslated(txt):
                    untranslated_warnings += 1

        print(f"Archivos revisados:           {len(html_files)}")
        print(f"Total párrafos:               {total_p}")
        print(f"Errores XML:                  {xml_errors}")
        print(f"Párrafos en posible inglés:   {untranslated_warnings}")
        if xml_errors == 0 and untranslated_warnings == 0:
            print("[AUDIT PASS] 100% traducido al español con estructura XHTML y XML perfecta!")
        print("=" * 60)


# -----------------------------------------------------------------------------
# CLI PRINCIPAL
# -----------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Traductor Universal de EPUBs con IA (MiniMax & OpenAI Compatible)"
    )
    parser.add_argument(
        "--input", type=str, required=False, help="Ruta del archivo EPUB a traducir"
    )
    parser.add_argument(
        "--output", type=str, default=None, help="Ruta de salida del EPUB traducido"
    )
    parser.add_argument(
        "--profile", type=str, default=None, help="Ruta a un archivo book_profile.json"
    )
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="Inspeccionar y mostrar metadatos del EPUB",
    )
    parser.add_argument(
        "--generate-profile",
        action="store_true",
        help="Generar perfil literario del libro con IA",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Probar conectividad con el modelo configurado",
    )
    parser.add_argument(
        "--model",
        type=str,
        default=DEFAULT_MODEL,
        help=f"Modelo LLM (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--base-url",
        type=str,
        default=DEFAULT_BASE_URL,
        help=f"Base URL (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument("--api-key", type=str, default=None, help="API Key (or set AI_API_KEY env)")
    parser.add_argument("--batch-size", type=int, default=6, help="Tamaño de lote (default: 6)")
    parser.add_argument(
        "--context-window",
        type=int,
        default=3,
        help="Sliding-window context: paragraphs of recent translations (default: 3)",
    )
    parser.add_argument("--single-batch", type=int, default=None, help="Ejecutar solo N lotes")
    parser.add_argument(
        "--fix-checkpoint",
        action="store_true",
        help="Auditar y purgar checkpoint del libro",
    )
    parser.add_argument("--audit", action="store_true", help="Auditar archivo de salida")
    parser.add_argument(
        "--state-dir",
        type=str,
        default=None,
        help="Override state root (else TRANSLATE_EPUB_STATE_DIR, else <input>/.translate_epub)",
    )
    parser.add_argument(
        "--strict-toc",
        action="store_true",
        help="Exit 1 if any TOC warning is emitted (malformed or missing TOC)",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Override output directory; EPUB lands at <dir>/<stem> (Español).epub",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Run epubcheck on the output EPUB (Java tool; skipped if not installed)",
    )

    args = parser.parse_args()

    def get_client_lazy() -> OpenAI:
        """Resolve credentials + build client only when an LLM call is actually needed."""
        return get_client(api_key=resolve_api_key(args.api_key), base_url=args.base_url)

    if args.test:
        client = get_client_lazy()
        print("=" * 60)
        print("Probando conectividad LLM...")
        print(f"Base URL: {client.base_url}")
        print(f"Modelo:   {args.model}")
        print("=" * 60)
        try:
            res = client.chat.completions.create(
                model=args.model,
                messages=[{"role": "user", "content": "Di 'Conexión exitosa'"}],
                max_tokens=20,
            )
            raw = res.choices[0].message.content or ""
            clean = re.sub(r"<think>.*?</think>", "", raw, flags=re.DOTALL).strip()
            print(f"[OK] Respuesta: {clean}")
            print("[TEST COMPLETADO CON ÉXITO]")
        except OpenAIError as e:
            print(f"[ERROR] Conexión fallida: {e}")
        return

    if not args.input:
        parser.print_help()
        sys.exit(1)

    input_path = Path(args.input).resolve()
    inspector = EPUBInspector(input_path)
    info = inspector.extract_info()

    if args.inspect:
        print("\n" + "=" * 60)
        print(f"INSPECCIÓN DE EPUB: {input_path.name}")
        print("=" * 60)
        print(f"BLAKE3 (ID):      {info['file_sha']}")
        print(f"Título:           {info['metadata'].get('title')}")
        print(f"Autor:            {info['metadata'].get('creator')}")
        print(f"Idioma:           {info['metadata'].get('language')}")
        print(f"Total Capítulos:  {len(info['spine_files'])}")
        print(f"Total Párrafos:   ~{info['total_paragraphs']}")

        # Smoke-test feature_detect_toc by extracting to a temp workspace.
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            tmpdir = Path(tmp)
            with zipfile.ZipFile(input_path, "r") as z:
                z.extractall(tmpdir)
            ncx_files, nav_files = feature_detect_toc(tmpdir)
            n_entries = sum(len(parse_ncx(p.read_bytes())) for p in ncx_files)
            v_entries = sum(len(parse_navdoc(p.read_bytes())) for p in nav_files)
            print(f"TOC NCX:          {len(ncx_files)} file(s), {n_entries} entries")
            print(f"TOC NavDoc:       {len(nav_files)} file(s), {v_entries} entries")

        print("\nSinopsis / Descripción:")
        print(info["metadata"].get("description", "(Sin descripción)"))
        print("=" * 60)
        return

    # Resumen visual previo de la obra
    meta = info["metadata"]
    print("=" * 60)
    print(f"LIBRO:   {meta.get('title', input_path.stem)}")
    print(f"AUTOR:   {meta.get('creator', 'Desconocido')}")
    print(
        f"SPINE:   {len(info['spine_files'])} documentos XHTML | "
        f"~{info['total_paragraphs']} párrafos"
    )
    print(f"HASH ID: {info['file_sha']}")
    print("=" * 60)

    # Determinación del state root + rutas (REQ-010, REQ-011)
    state_root = resolve_state_dir(
        input_path,
        override=args.state_dir,
        env_value=os.environ.get("TRANSLATE_EPUB_STATE_DIR"),
    )
    paths = book_state_paths(state_root, info["file_sha"])
    paths["book_dir"].mkdir(parents=True, exist_ok=True)
    profile_path = Path(args.profile).resolve() if args.profile else paths["profile"]
    checkpoint_file = paths["checkpoint"]
    work_dir = paths["workspace"]

    if args.generate_profile:
        client = get_client_lazy()
        generate_book_profile(client, args.model, info, profile_path)
        return

    if profile_path.exists():
        print(f"[PERFIL] Cargando perfil existente desde: {profile_path}")
        with open(profile_path, encoding="utf-8") as f:
            profile: BookProfile = json.load(f)
    else:
        print(f"[PERFIL] No existe {profile_path}. Auto-generando perfil con IA por primera vez...")
        client = get_client_lazy()
        profile = generate_book_profile(client, args.model, info, profile_path)

    client = get_client_lazy()
    translator = UniversalBatchTranslator(
        client=client,
        model=args.model,
        profile=profile,
        checkpoint_file=checkpoint_file,
        context_window=args.context_window,
    )

    if args.fix_checkpoint:
        translator.purge_invalid_entries()
        return

    # Ruta de salida (REQ-012: location-independent; --output-dir overrides parent dir).
    if args.output:
        output_path = Path(args.output).resolve()
    elif args.output_dir:
        out_dir = Path(args.output_dir).expanduser().resolve()
        out_dir.mkdir(parents=True, exist_ok=True)
        output_path = out_dir / f"{input_path.stem} (Español).epub"
    else:
        output_path = input_path.parent / f"{input_path.stem} (Español).epub"

    if args.audit:
        audit_epub(output_path)
        return

    toc_warned = process_universal_epub(
        input_path=input_path,
        output_path=output_path,
        translator=translator,
        inspector_info=info,
        work_dir=work_dir,
        batch_size=args.batch_size,
        single_batch_only=args.single_batch,
    )

    # REQ-053: persist chapter_titles after successful checkpoint (atomic).
    if translator.profile.get("chapter_titles"):
        try:
            atomic_write_json(profile_path, dict(translator.profile))
        except OSError as e:
            print(f"[WARN] cannot persist profile chapter_titles: {e}")

    audit_epub(output_path)

    # REQ-014: --validate runs epubcheck (Java tool); skipped gracefully if absent.
    if args.validate:
        try:
            proc = subprocess.run(
                ["epubcheck", str(output_path)],
                capture_output=True,
                text=True,
                timeout=120,
            )
        except FileNotFoundError:
            print("[VALIDATE] epubcheck not installed; skipping validation")
        except subprocess.TimeoutExpired:
            print("[VALIDATE] epubcheck timed out; skipping validation")
        else:
            combined = (proc.stdout or "") + (proc.stderr or "")
            if proc.returncode == 0:
                print("[VALIDATE] epubcheck: OK")
            else:
                print(f"[VALIDATE] epubcheck exit {proc.returncode}:\n{combined}")

    if args.strict_toc and toc_warned:
        print(
            "[STRICT-TOC] TOC warnings detected — exiting with status 1",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
