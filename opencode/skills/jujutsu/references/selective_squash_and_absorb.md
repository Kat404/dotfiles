# Scenario: Refactoring via Selective Squash and Non-Interactive Split

## Context & Goal

The agent needs to redistribute changes across historical commits in a stack (such as isolating documentation, separating schema from routes, or propagating lint fixes) without triggering interactive hunk-selection UIs.

## Execution Trace

### 1. Automatic Propagation via `jj absorb`

When small fixes or formatting changes in the working copy belong to distinct ancestor commits:

```bash
# Working copy (@) contains edits across multiple files/lines
# jj absorb examines which historical commit in the stack modified those lines:
jj absorb

# Result: Matching hunks are moved directly into their respective ancestor commits.
# Any changes that cannot be mapped unambiguously remain in the working copy (@).
```

### 2. Explicit Path Squash into a Specific Ancestor

Move modifications made to a specific path from `@` directly into a target ancestor revision:

```bash
TARGET_REV=$(jj log --no-graph -T "change_id" -r "@--")

# Squash ONLY the configuration file into the grandparent commit
jj squash --into "$TARGET_REV" config/settings.toml
```

### 3. Non-Interactive Split by File Paths

Extract a subset of modified files from `@` into their own dedicated preceding commit:

```bash
# Working copy currently has: src/models.rs, src/routes.rs, docs/api.md
# Split out docs and models into a parent commit non-interactively:
jj split docs/api.md src/models.rs -m "docs(api): document data contract and add schemas"

# Result:
# @- now contains docs/api.md and src/models.rs with the provided message
# @ contains ONLY src/routes.rs with empty/previous description
```

## Invariant Assertions

```bash
# 1. Verify target ancestor contains the squashed file
jj diff --summary -r "$TARGET_REV" | grep -q "config/settings.toml"

# 2. Verify working copy is clean or contains only the intended remainder
jj diff --summary
```

## Failure Modes & Recovery

- **Absorb did not move lines:** Occurs when modified lines are new additions rather than updates to lines touched by ancestors. Use explicit `jj squash --into <rev> <path>` instead.
- **Wrong files squashed:** Immediately revert with `jj undo`.
