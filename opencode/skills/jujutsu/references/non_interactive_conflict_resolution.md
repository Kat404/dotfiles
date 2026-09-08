# Scenario: Non-Interactive Conflict Resolution

## Context & Goal

Jujutsu treats conflicts as first-class data inside commits; conflicts never abort rebases or pause execution. An autonomous agent must programmatically detect, parse, and resolve conflicts across files without opening interactive diff editors (`$EDITOR`, `diff-editor`, or `jj resolve`).

## Execution Trace

### 1. Fetch Remote & Rebase Stack onto Updated Trunk

```bash
jj git fetch
jj rebase -d trunk()
```

### 2. Check for Conflicted Commits

```bash
# Detect if any visible revisions contain unresolved conflicts
CONFLICTING_REVS=$(jj log --no-graph -T "change_id ++ '\n'" -r "conflict()")

if [ -n "$CONFLICTING_REVS" ]; then
    echo "Conflicts detected in revisions: $CONFLICTING_REVS"
fi
```

### 3. Switch to the First Conflicted Revision

```bash
FIRST_CONFLICT=$(echo "$CONFLICTING_REVS" | head -n 1)
jj edit "$FIRST_CONFLICT"
```

### 4. List Specific Conflicted Files

```bash
# Identify conflicting file paths
jj status
# Conflicted files will appear under the "Conflicts:" section
```

### 5. Resolution Strategy A: Direct File Marker Parsing

Jujutsu writes standard conflict markers directly into the filesystem copy:

- `<<<<<<<` (Left / Target parent)
- `|||||||` (Base / Common ancestor)
- `>>>>>>>` (Right / Source being rebased)

```bash
# 1. Agent reads the conflicted file via workspace read tools
# 2. Agent reasons through logic and writes the resolved code removing all markers
# 3. Verify markers are completely gone:
grep -rnE '^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)' path/to/file.ext && echo "Markers still present!" || echo "Clean"
```

_Note: Jujutsu automatically marks the path as resolved the moment file markers are removed and the file is saved._

### 6. Resolution Strategy B: Wholesale Replacement from Revision

When one side should entirely win:

```bash
# Overwrite file completely using trunk version
jj restore --from trunk() path/to/file.ext

# OR overwrite using the side being introduced (@-)
jj restore --from @- path/to/file.ext
```

## Invariant Assertions

```bash
# 1. Verify this revision is no longer marked as conflicted
test -z "$(jj log --no-graph -T "change_id" -r "@ & conflict()")"

# 2. Verify entire repository DAG is clear of conflicts
test -z "$(jj log --no-graph -T "change_id" -r "conflict()")"
```

## Failure Modes & Recovery

- **Partially cleaned markers:** If `jj status` still lists the file under "Conflicted files", search for residual `>>>>>>>` or `<<<<<<<` lines.
- **Irrecoverable merge mistake:** Revert the entire resolution back to the initial conflicted state using `jj undo`.
