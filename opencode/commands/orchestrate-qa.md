---
description: Orquestar qa-doctor + code-flow-analyst (paralelo) → fixer (secuencial). Re-verifica al final. El agente primario (tú) ejecuta este command cuando termine un bloque de cambios para verificar antes de commitear.
---

# Orchestrate QA — qa + analyst + fixer en orden

Use this command after a non-trivial code change to verify quality
end-to-end. The primary agent invokes the 3 subagents via the
`task` tool.

## Step 1 — Detect changed files

Before invoking the subagents, snapshot which files you changed so
the prompts can include them:

```bash
git diff --name-only HEAD
```

(If the repo isn't a git repo, use whatever change-tracking the
project has. If nothing, list the files you edited in this turn.)

## Step 2 — Run qa-doctor + code-flow-analyst in parallel

Both are read-only. Launch them simultaneously via two `task` calls,
then wait for both results.

```python
# Pseudocode; adapt to your environment's task tool signature
task(
  subagent_type="qa-doctor",
  prompt=(
    "Files changed in this session:\n<list from step 1>\n"
    "Summary of changes:\n<one-paragraph summary>\n"
    "Run ruff format/check, ty check, and pytest (if available). "
    "Report PASS/FAIL with raw counts."
  ),
)

task(
  subagent_type="code-flow-analyst",
  prompt=(
    "Files changed in this session:\n<list from step 1>\n"
    "Summary of changes:\n<one-paragraph summary>\n"
    "Analyze for: public surface changes, side effects, error paths, "
    "type contracts, data flow leakage, concurrency/memory, security, "
    "determinism, performance. Stack-agnostic. Read-only."
  ),
)
```

## Step 3 — Collect reports

Wait for both `task().result()`. Each returns a structured report:

- `qa-doctor`: per-tool PASS/FAIL counts + format drift + summary line
  `qa: N passed, M failed, ...`.
- `code-flow-analyst`: `[RED]` / `[ORANGE]` findings in Markdown +
  `[YELLOW]` findings in ponytail-style one-liners + summary
  `analysis: R red, O orange, Y yellow`.

If qa-doctor reports `Lean already. Ship.` AND code-flow-analyst
reports `Lean already. Ship.`, **stop here** — skip Step 4 (no fixer
needed). Otherwise continue.

## Step 4 — Run fixer if there are findings

Consolidate all findings from both reports into one task prompt.
Pass them VERBATIM to the fixer; do not paraphrase the file:line or
the recommendation.

```python
if findings_exist:
    task(
      subagent_type="fixer",
      prompt=(
        "Files changed: <list>\n"
        "Findings to apply (verbatim from qa-doctor and code-flow-analyst):\n"
        "<paste full findings section>\n"
        "Apply EXACT fixes. No new features, no scope creep. "
        "End with READY FOR RE-TEST or BLOCKED: <reason>."
      ),
    )
```

The fixer will return either `READY FOR RE-TEST` (fixes landed) or
`BLOCKED: <reason>` (e.g. a test broke because of a contract change).
If BLOCKED, surface the blocker to the user before proceeding.

## Step 5 — Re-verify with qa-doctor

After the fixer reports `READY FOR RE-TEST`, run qa-doctor one more
time on the fixed files to confirm the checks pass now.

```python
task(
  subagent_type="qa-doctor",
  prompt=(
    "Re-verify post-fix. Files affected: <list>. "
    "Run ruff format/check, ty check, pytest. Report final counts."
  ),
)
```

## Step 6 — Report to user

Summarize the orchestration result in 3-5 lines:

- Tests passed/failed.
- Findings fixed (count by severity).
- Any BLOCKED items the user needs to decide on.
- Whether the change is safe to commit.

Then commit using your normal git workflow.

## Notes

- The 3 subagents are READ-ONLY (qa-doctor, code-flow-analyst) or
  apply-only (fixer). They never commit. They never modify git state.
- Use this command between major edits, not after every tiny change.
- For trivial changes (1-2 lines, no contract changes), running
  qa-doctor alone is usually enough.
- The fixer respects `git config` and `.git/config` boundaries; do
  NOT let it commit or amend.
