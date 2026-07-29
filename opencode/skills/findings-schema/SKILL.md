---
name: findings-schema
description: >
  Trigger when emitting or consuming review findings (qa-doctor, code-flow-analyst, fixer → craft). Enforces JSON envelope shape, severity taxonomy, evidence_class, causal_disposition, sentinel_kind discriminator.
---

# Findings JSON envelope schema

## Activation

Trigger when a subagent emits review findings (`qa-doctor`, `code-flow-analyst`) OR craft consumes the `## Review-Ledger` section of a plan. Applies to every per-finding record and the top-level envelope.

## Hard Rules

- **Top-level keys:** only `findings` (array) and `evidence` (array). Any other top-level key = contract violation.
- **`findings: []` (empty)** = clean. `findings` non-empty = list of finding records.
- **Per-finding keys:** exactly 6 — `location`, `severity`, `claim`, `evidence_class`, `causal_disposition`, `proof_refs`. Missing `proof_refs[]` (even empty) = contract violation.
- **Severity enum** (review vocab, NOT drift-guard vocab): `BLOCKER | CRITICAL | WARNING | SUGGESTION`. Drift guards `[RED]/[ORANGE]/[YELLOW]` are chart-only.
- **`evidence_class` enum:** `deterministic | inferential | insufficient`.
- **`causal_disposition` enum:** `introduced | behavior-activated | worsened | pre-existing | base-only | unknown`.
- **`sentinel_kind`** (optional): `"truncation"` or `"coverage"`. Absence = real defect, not sentinel.

## Decision Gates

| Situation                                         | Action                                                       |
| ------------------------------------------------- | ------------------------------------------------------------ |
| Empty findings                                    | emit `{"findings": [], "evidence": []}`                      |
| Findings with mixed severities                    | emit full envelope, do NOT filter BLOCKER/CRITICAL silently  |
| Sentinel findings (`sentinel_kind` set)           | surface to user, do NOT route to fixer (sentinels are not code defects) |
| Missing `proof_refs[]` field                      | emit empty array `[]`; missing field = contract violation    |
| Unknown severity value                            | reject; do NOT emit                                          |

## Steps

1. Collect findings from per-file/per-line checks.
2. For each finding, populate all 6 required keys.
3. Wrap in `{"findings": [...], "evidence": [...]}`.
4. If any finding has `sentinel_kind` set → surface to user, block shipment until acknowledged.

## Output Contract

- Single JSON object: `{"findings": [...], "evidence": [...]}`.
- Each finding: 6 required keys, no others.
- Scoreboard literal (qa-doctor): `qa: <N> tests passed, <M> failed, <K> lints, <J> format drift. PASS|FAIL`.
- Analysis literal (code-flow-analyst): `analysis: <R> blocker, <C> critical, <W> warning, <S> suggestion`.

## References

- `~/.dotfiles/opencode/contracts/review-integration/v1/schemas/result-artifact-v2.schema.json` — canonical JSON schema.
- `~/.config/opencode/AGENTS.md §Severity taxonomy` — disjoint drift-guard vs finding vocab.
- `craft.md` §Plan consumption — consumer-side routing.
- `qa-doctor.md` + `code-flow-analyst.md` — emitter-side.