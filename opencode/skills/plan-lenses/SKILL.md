---
name: plan-lenses
description: >
  Trigger when Mitril enters Step 2.5 "Walk planning lenses" before drafting. Enforces
  4 lenses (R1-scope-fit, R2-dependency, R3-rollback, R4-cost). Outputs R-mismatches
  inline so Mitril can surface them in ## Risks.
---

# Plan lenses

## Activation

Loaded when Mitril's Step 2.5 invokes the skill (before emitting `## Proposal`).

## Hard Rules

- Apply all 4 lenses; no skipping.
- Every mismatch MUST have an explicit mitigation, not just a label.
- R-mismatches go into `## Risks` of the plan; nothing else.

## Decision Gates

| Lens | Question | Mismatch → drift-guard tag |
|------|----------|----------------------------|
| R1 scope-fit | Does the request fit 1-unit-per-`## Tasks`-line? | `[RED]` if request spans >3 layers without decomposition |
| R2 dependency | What blocks execution (permissions, missing context, external state)? | `[ORANGE]` if external state needed |
| R3 rollback | Is the rollback reversible? | `[RED]` if permanent state (DB migrations, deletes, history rewrites) without a tested undo |
| R4 cost | Token / network / package cost? | `[YELLOW]` if unbounded |

## Steps

1. Read the intent + surface from Step 1 / Step 1.5 / Step 2 output.
2. For each of R1-R4, answer its question. If answer = "yes, mismatch", name the specific risk.
3. Convert each mismatch to a Risks-table row: `risk | likelihood | mitigation`.
4. Return the populated Risks table to Mitril; Mitril inserts into `## Proposal`.

## Output Contract

- Markdown table with 0-N rows.
- Each row: 3 columns. Mitigation is non-empty.
- Severities map to drift-guard tags (not review findings).

## References

- `~/.config/opencode/AGENTS.md §Plan template` — the canonical 5-section shape.
- `~/.dotfiles/opencode/agents/mitril.md §Method` — Step 2.5 is the caller.
- `~/.config/opencode/skills/skill-style-guide/SKILL.md` — style guide for this file.
