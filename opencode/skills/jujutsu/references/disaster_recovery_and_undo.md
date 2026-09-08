# Scenario: Disaster Recovery, Operation Log Inspection, and Tree Cleanup

## Context & Goal

Autonomous agents can make invalid rebases, abandon wrong commits, or apply unintended file mutations. This reference specifies deterministic rollback mechanisms using Jujutsu's atomic Operation Log.

## Execution Trace

### 1. Immediate Single-Command Rollback

```bash
# Reverts the exact state of the entire repository prior to the last command
jj undo
```

### 2. Inspecting Operation History Machine-Readably

When recovery requires jumping further back than 1 command:

```bash
# Print last 5 operations with short ID and description
jj op log --no-graph --limit 5 --template 'id.short() ++ " | " ++ description ++ "\n"'

# Example Output:
# a1b2c3d4 | rebase commit 8f4e2a to trunk()
# e5f6a7b8 | describe commit 8f4e2a
# 9c8b7a6d | snapshot working copy
```

### 3. Restoring Repo State to a Known Safe Operation ID

```bash
# Undo all actions back to the state after operation e5f6a7b8
jj op undo e5f6a7b8
```

### 4. Pruning Stale or Unwanted Commits

To delete an experimental or broken commit from the DAG without leaving orphan working copy pointers:

```bash
# Discard change; children are automatically re-parented onto the target's parent
jj abandon <unwanted-change-id>
```

### 5. Cleaning Abandoned / Empty Commits in Stack

```bash
# Find and abandon all empty mutable commits in the current stack
EMPTY_COMMITS=$(jj log --no-graph -T "change_id ++ '\n'" -r "empty() & (trunk()..@)")

for rev in $EMPTY_COMMITS; do
    jj abandon "$rev"
done
```

## Invariant Assertions

```bash
# 1. Confirm working copy is situated on a valid, non-empty commit (or clean draft)
jj status

# 2. Check that no untracked conflict markers or broken rebases remain
test -z "$(jj log --no-graph -T "change_id" -r "conflict()")"
```

## Failure Modes & Recovery

- **Double Undo Confusion:** Running `jj undo` twice does NOT redo; it reverts the undo operation. To navigate forward and backward reliably, inspect `jj op log` and target exact operation IDs via `jj op undo <op-id>`.
