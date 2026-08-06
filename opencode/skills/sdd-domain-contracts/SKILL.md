---
name: sdd-domain-contracts
description: >
  Language Domain Contract — controls how personas and tone affect technical artifacts.
  Loaded by phases that produce code, comments, specs, or tasks.
  Covers regla #3 (Language Domain Contract).
---

## Activation

TRIGGER when:
- A phase agent is about to write technical artifacts (code, comments, specs, designs, tasks)
- A user requests artifacts in a non-default language
- Delegating work to a sub-agent that may inherit persona voice

## Hard Rules

1. **Conversation isolation**: the active persona controls direct user/orchestrator conversation only. Use it for direct replies, clarification prompts, and user-facing orchestration status.
2. **Technical defaults to English**: generated technical artifacts default to English regardless of active persona or conversation language. Includes: OpenSpec files, specs, designs, tasks, code comments, UI copy, tests, fixtures, delegated phase outputs.
3. **Explicit language override**: if technical artifacts are explicitly requested in another language, use a neutral/professional register unless the user explicitly requests a different tone or regional variant.
4. **Public context comments**: follow the target context language by default. Explicit user language or tone overrides win; otherwise use a neutral/professional register unless the target context clearly calls for another tone or regional variant.
5. **Forward to executor**: when delegating, forward this contract to the executor so persona voice NEVER becomes the artifact or public-comment default.

## Decision Gates

- DECISION: is this artifact technical? → RULE #2 (default English)
- DECISION: did user explicitly request non-English artifact? → RULE #3 (neutral register)
- DECISION: persona active in conversation? → RULE #1 (don't bleed into artifact)

## Steps

1. **Identify artifact type**: technical (code, spec, design, task) vs conversational (status, summary).
2. **Determine language**: default English for technical. Default to user language for conversational.
3. **If explicit override**: apply user-requested language with neutral register.
4. **Strip persona voice**: ensure no first-person commentary, jerga, or tone markers in technical output.
5. **Forward contract**: when delegating to sub-agent, include this contract in the prompt.

## Output Contract

Technical artifacts in English (default) with neutral register. Persona voice only in:
- Direct reply to user
- Clarification prompt
- Orchestration status

## References

- `gentle-ai/internal/assets/generic/sdd-orchestrator.md:37-43` — Language Domain Contract canonical.
- `gentle-ai/internal/assets/opencode/sdd-orchestrator.md:35-41` — OpenCode variant.
