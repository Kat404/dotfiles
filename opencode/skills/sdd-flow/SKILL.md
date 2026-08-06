---
name: sdd-flow
description: >
  SDD flow control for OpenCode. Routing, preflight, init guard, gatekeeper, and review workload.
  Use when invoking /sdd-new, /sdd-continue, /sdd-ff, /sdd-apply, /sdd-verify, /sdd-archive, or when parent orchestrator moves to SDD mode.
  Loaded by parent before dispatching any phase agent.
---

## Activation

TRIGGER when:
- User invokes `/sdd-new`, `/sdd-ff`, `/sdd-continue`, `/sdd-explore`, `/sdd-apply`, `/sdd-verify`, `/sdd-archive`
- Parent prompt mentions SDD lifecycle, proposal, tasks, or artifact store
- Phase task fingerprint matches `(phase, repo, change-name)`

## Hard Rules

1. **Preflight (HARD GATE — regla #8)**: Before any `/sdd-*`, parent MUST collect 4 decisions in ONE `question` call: Pace (interactive/automatic), Artifacts (engram/openspec/hybrid), Chained-PR (auto-forecast/ask-always/single-pr-default/force-chained), Review Budget (400/800/Other). Cache for session. `/sdd-preflight` command is the entry point.
2. **Init Guard (regla #9)**: Parent MUST `mem_search("sdd-init/{project}")` before any phase. If empty → run init silently. NEVER mark preflight complete without explicit user answer.
3. **Dispatcher Guard (regla #7)**: Resolve artifact store from preflight. If `engram` → NEVER invoke native dispatcher (it is blind to engram-backed changes). Resolve status via `mem_search` + `mem_get_observation` on topic keys (e.g. `sdd/{change-name}/tasks`). If `openspec`/`hybrid` → dispatcher authoritative when available, route by `nextRecommended` and dependency states.
4. **Auto Mode Gatekeeper (regla #10)**: Between phases in automatic mode, validate 5 checks: (a) contract conformance (6-field envelope), (b) artifact existence (read-back from active backend), (c) no hallucination (spot-check concrete claims), (d) no drift (output consistent with required inputs), (e) routing coherence (next_recommended follows DAG). Inline for low-risk phases (explore/spec/tasks/archive). Fresh-context for design/apply. Re-run once on FAIL with corrective feedback; second FAIL → STOP.
5. **Review Workload (regla #12)**: After `sdd-tasks` and before `sdd-apply`, compute estimated changed lines. <400 → proceed as single PR. 400-800 → ask or auto-chain per delivery_strategy. >800 → size:exception. Unknown → STOP, surface to user.

## Decision Gates

- DECISION: which artifact store? → see Hard Rule #1 (preflight cache)
- DECISION: re-run phase on gate FAIL? → RULE #4 (once, then STOP)
- DECISION: deliver as chained PR? → RULE #5 (delivery_strategy from preflight)
- DECISION: route to dispatcher or memory? → RULE #3 (artifact store)

## Steps

1. **Resolve artifact store**: read preflight cache or `mem_search("sdd-init/{project}")`.
2. **Init guard**: if missing, run `sdd-init` silently before dispatching.
3. **Pre-dispatch check**: confirm artifact store matches the phase's expected backend.
4. **Dispatch phase**: delegate to `sdd-<phase>` sub-agent via `task` allowlist.
5. **Receive result**: parse 6-field envelope (`status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, `skill_resolution`).
6. **Gate**: run 5 checks from RULE #4. PASS → continue. FAIL → re-run once with feedback, then STOP.
7. **Log dedup fingerprint**: register `(phase, task-fingerprint)` in plugin `sdd-launch-dedup` ledger.
8. **Deliver**: when chain completes, archive with `sdd-archive`.

## Output Contract

PARENT receives: 6-field envelope per phase + `next_recommended` token for chaining.
USER receives: phase-scoped summary in conversational language; final batch report on chain completion.

## References

- `AGENTS.md §Native RAR policy` — Safety Net, scope by tag, cap.
- `AGENTS.md §SDD Glossary` — SDD/RDD/RAR definitions.
- `mitril.md §SDD Orchestrator Contracts` — parent-side orchestration.
- `skills/sdd-phase-contract/SKILL.md` — 6-field envelope schema.
- `skills/sdd-lossless-prompts/SKILL.md` — choice envelope preservation.
- `commands/sdd-preflight.md` — preflight entry point.
- `plugins/sdd-launch-dedup/` — fingerprint dedup.
