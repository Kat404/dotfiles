---
name: skill-style-guide
description: >
  Trigger when creating/migrating SKILL.md. Enforces 7-section canonical (Activation → Hard Rules →
  Decision Gates → Steps → Output Contract → References) + 180–450 token body budget.
---

# Skill style guide

## Activation

Trigger when: creating a new SKILL.md; migrating an existing skill to the canonical shape.

**Note (v0.1+)**: this skill itself was authored against the source `/tmp/gentle-ai/docs/skill-style-guide.md`, not against its own canonical shape. From v0.1 onward, all skills (including this one on re-edit) must follow this 7-section shape.

## Hard Rules

- Body 180–450 tokens. Recommended max 700. Hard max 1000. Overrun requires `ponytail: <ceiling>, <upgrade path>` marker.
- Required sections (in this exact order): Frontmatter → Activation → Hard Rules → Decision Gates → Steps → Output Contract → References.
- No "Why we chose X" history in skills — context bloat.
- No external URLs as primary references.
- Frontmatter `description` ≤250 chars, trigger words first.

## Decision Gates

| Situation                                                                         | Action                                                                                                                     |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| New skill                                                                         | full 7-section canonical.                                                                                                  |
| Migrate existing                                                                  | same 7-section; mark `ponytail: pre-style-guide, migrate on edit` for any section left incomplete.                         |
| Trivial: body ≤120 tokens AND ≤2 Hard Rules AND no table in Steps/Output Contract | collapse Steps + Output Contract into a single section; keep Frontmatter + Activation + Hard Rules. Document the collapse. |
| Body has tables spanning 3+ columns                                               | move example tables to `assets/` or `references/`.                                                                         |
| Skill touches other skills' domains                                               | STOP. Surface to user; do not extend scope.                                                                                |

## Steps

1. Read existing skill (if migration) or design doc / spec.
2. Draft Frontmatter: `name`, `description` (trigger words first), `license`, `metadata.author`, `metadata.version`.
3. Fill Activation, encode Hard Rules, list Decision Gates.
4. Write Steps + Output Contract (sequence; output shape).
5. Add References only if non-obvious (local files only).

## Output Contract

- One `.md` file at the skill's expected path under `~/.config/opencode/skills/<name>/SKILL.md`.
- All 7 sections present unless trivial collapse documented.
- Frontmatter: `name` + `description` (≤250 chars, quoted single line, trigger-preserving).

## References

- `/tmp/gentle-ai/docs/skill-style-guide.md` — canonical source (lifted 2026-07-26). Caveat: `/tmp/` may be wiped; mirror this skill's body if the source is gone. Provenance line above is the audit anchor.
- `~/.config/opencode/skills/caveman/SKILL.md` — pre-style-guide skill, will migrate on next-touch.
- AGENTS.md §Severity taxonomy — cross-reference for disjoint vocab rules that skills may need to enforce.
