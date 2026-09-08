# Scenario: Stacked Changes & Micro-Commits Workflow

## Context & Goal

The agent needs to build a multi-tiered feature set (e.g., schema -> business logic -> API endpoint) as a chain of small, reviewable dependent changes (stacked diffs) without waiting for upstream PR merges, and modify intermediate commits with automatic child rebasing.

## Execution Trace

### 1. Initialize First Change in Stack (Data Layer)

```bash
# Ensure work starts on top of trunk
jj new trunk() -m "feat(db): add session schema definitions"

# (Agent creates src/db/session.rs...)

# Advance to second change while leaving db change recorded in @-
jj new -m "feat(auth): implement session validation middleware"
```

### 2. Add Dependent Change (Middleware Layer)

```bash
# (Agent creates src/auth/middleware.rs...)

# Advance to third change
jj new -m "feat(api): expose authenticated profile route"
```

### 3. Add Top of Stack (API Layer)

```bash
# (Agent creates src/routes/profile.rs...)
```

### 4. Amend an Intermediate Change in the Stack

Requirement: The agent realizes `src/db/session.rs` needs an additional TTL field without manually reordering or running interactive rebases.

```bash
# Target the bottom commit using revset navigation (@-- is the grandparent)
# Or identify by change ID:
DB_CHANGE_ID=$(jj log --no-graph -T "change_id" -r "@--")

# Switch working copy to the database commit
jj edit "$DB_CHANGE_ID"

# (Agent modifies src/db/session.rs to add TTL field...)

# Return working copy back to the top of the stack
# Jujutsu automatically rebases auth and api commits on top of the modified db commit
TIP_CHANGE_ID=$(jj log --no-graph -T "change_id" -r "heads(@::)")
jj new "$TIP_CHANGE_ID"
```

## Invariant Assertions

```bash
# 1. Verify linear DAG topology from trunk to working copy
jj log -r "trunk()..@ | @"

# 2. Verify no unresolved conflicts were introduced during the auto-rebase
test -z "$(jj log --no-graph -T "change_id" -r "conflict()")"

# 3. Verify the working copy has no unintended leftover diffs
jj diff --quiet
```

## Failure Modes & Recovery

- **Accidental detached commit during branch hop:** If the agent ends up with divergent branches, run `jj rebase -s <divergent-change> -d <intended-parent>` to linearize the stack.
- **Auto-rebase conflict:** If editing an intermediate commit breaks a child commit, refer directly to `references/03_non_interactive_conflict_resolution.md`.
