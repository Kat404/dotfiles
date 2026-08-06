---
name: sdd-phase-contract
description: >
  SDD phase result contract — the 6-field envelope that every phase agent MUST return.
  Plus ledger semantics (Native Runtime Attempt Authority) and defect handoff.
  Loaded by parent (mitril/sdd-flow) between phases.
  Covers reglas #11 (attempt authority), #6 (RAR owns verification), #2 (defect handoff).
---

## Activation

TRIGGER when:
- Any `sdd-*` phase agent is about to return its result
- Parent reads phase result to validate before dispatching next phase
- Reviewing whether a sub-agent's output is acceptable for chain continuation

## Hard Rules

1. **6-field envelope required**: every phase result MUST contain exactly these 6 keys: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, `skill_resolution`.
2. **Status enum**: `ok` | `partial` | `failed` | `blocked`. Anything else FAILS the gate.
3. **Attempts monotonic (regla #11)**: An attempt is consumed when `acquire` succeeded (`state: proceed`). Retries, restarts, or new worker calls do NOT reset the counter. Fourth attempt opens only after explicit user decision.
4. **Settlement idempotent**: `settle` derives binding/remediation inputs. Settle's request-id MUST be distinct from acquire's. Reuse each operation's own id only for its own idempotent replay.
5. **Defect handoff (regla #2)**: If status indicates `failed` due to provider defect (not user error), DO NOT auto-create GitHub issue. Surface to user, get explicit consent, then privacy-scrub + duplicate search + create (or comment if exists).

## Decision Gates

- DECISION: phase result PASS? → must satisfy 6-field envelope + status ∈ {ok, partial-with-rationale}
- DECISION: provider defect vs user error? → if user can't fix, route to defect handoff (RULE #5)
- DECISION: re-run phase? → only if `status: failed` AND cause is transient; never loop-until-clean

## Steps

1. **Validate envelope**: parse result JSON, confirm 6 keys present.
2. **Validate status**: `status` MUST be in enum.
3. **Read-back artifacts**: for each path in `artifacts[]`, verify exists in active backend (engram: `mem_get_observation`; openspec: file path).
4. **Check risks**: scan `risks[]` for CRITICAL/severity-flagged items.
5. **Route next**: `next_recommended` must follow dependency graph (e.g. propose → spec → design → tasks → apply → verify → archive).

## Output Contract

```json
{
  "status": "ok|partial|failed|blocked",
  "executive_summary": "<1-2 line summary>",
  "artifacts": ["<path or topic-key>"],
  "next_recommended": "propose|spec|design|tasks|apply|verify|archive|resolve-blockers|none",
  "risks": [],
  "skill_resolution": {
    "skills_loaded": ["<name>"],
    "skills_skipped": ["<name>"],
    "provenance": "paths-injected|fallback-registry|fallback-path|none"
  }
}
```

## References

- `AGENTS.md §SDD Glossary` — Bounded correction, one-candidate-one-receipt.
- `mitril.md §SDD Orchestrator Contracts §Gatekeeper` — 5 checks.
- `gentle-ai/internal/assets/skills/_shared/persistence-contract.md` — artifact store contract.
- `gentle-ai/internal/assets/skills/_shared/sdd-phase-common.md` — protocol.
