---
name: sdd-lossless-prompts
description: >
  Lossless preservation of blocking choice prompts across sub-agent boundaries.
  When a sub-agent or tool returns a user-facing blocking prompt, preserve the complete
  envelope (why, groups, options, allowed-answer domain). Covers regla #1.
---

## Activation

TRIGGER when:
- A sub-agent or tool returns a blocking prompt (menu, choice envelope, `AskUserQuestion`)
- The native question UI is unavailable, denied, or the envelope is oversized
- A phase asks for clarification that requires user decision

## Hard Rules

1. **Preserve envelope completely**: never summarize, abbreviate, reorder, relabel, merge, or omit choices. Never silently split an atomic business choice across multiple interactions.
2. **Native route preferred**: use the platform's `question` tool ONLY when the complete choice envelope is exactly representable in one grouped interaction without truncation or reshaping.
3. **Fallback mandatory**: if native UI unavailable, runtime non-interactive, or envelope oversized, emit the COMPLETE choice envelope as plain chat or terminal response. Include the required answer syntax and why the input blocks progress. Then STOP.
4. **Answer validation**: accept an answer only when each response belongs to the EXACT allowed-answer domain for its group. Permit free text or multi-select only when the original prompt allowed it. If invalid or ambiguous, emit the envelope again and STOP.
5. **No silent inference**: never choose, default, infer, launch dependent work, or continue after emitting. The user MUST respond.

## Decision Gates

- DECISION: native UI usable? → use `question` tool, preserve domain
- DECISION: native UI fails or oversized? → plain chat fallback, STOP
- DECISION: answer valid? → RULE #4 (exact allowed-answer domain)

## Steps

1. **Detect envelope**: regex for `AskUserQuestion`, `question` tool, terminal menu.
2. **Inspect allowed-answer domain**: enumerate every group's options, selection mode, free text allowance.
3. **Choose route**: native `question` if fully representable, else plain chat fallback.
4. **Emit envelope**: complete copy of why, groups, options, mode, domain.
5. **STOP**: do not launch dependent work, do not infer.
6. **Validate answer**: must match allowed-answer domain exactly.
7. **Forward**: pass validated answer to the same blocked actor exactly once.

## Output Contract

A complete user-facing choice envelope:
- Why input is required
- Every group and question in original order
- Every group header
- Every option label and description
- Selection mode (single, multi, free text)
- Exact allowed-answer domain

## References

- `gentle-ai/internal/assets/opencode/sdd-orchestrator.md:9-16` — Lossless Blocking Prompts canonical.
- `gentle-ai/internal/assets/generic/sdd-orchestrator.md:11-18` — generic source.
