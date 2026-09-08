---
name: jujutsu
description: "Expert guide for Jujutsu (jj) VCS operations. Designed strictly for autonomous AI agents executing deterministic, non-interactive shell commands."
compatibility: "jj >= 0.20"
---

# Jujutsu (jj) Agent Skill

Jujutsu (`jj`) is a Git-compatible distributed version control system with an operation-log architecture, first-class conflicts, and no staging area.

---

## 1. Core Agent Rules & Safety Constraints

1. **NON-INTERACTIVE EXECUTION ONLY**:
   - NEVER run commands that open `$EDITOR` or a diff tool without arguments.
   - ALWAYS provide commit messages inline: `jj describe -m "<msg>"` (or `jj new -m "<msg>"`).
   - NEVER run bare `jj split` or `jj squash -i` (diff editors hang headless agent shells). Use path arguments: `jj split <path>...` or non-interactive alternatives (`jj squash --into <rev> <path>...`).
   - ALWAYS inspect diffs via `jj diff` directly or with path filters; never invoke interactive pagers.

2. **MUTATION BARRIER**:
   - **NEVER** execute mutating Git commands in a `jj` repo (`git commit`, `git checkout`, `git rebase`, `git merge`, `git reset`, `git stash`, `git cherry-pick`). Doing so desynchronizes or corrupts the working copy snapshot.
   - **ALLOWED** Git commands (read-only): `git log`, `git diff`, `git show`, `git blame`, `git rev-parse`.

3. **CHANGES VS COMMITS**:
   - `Change ID` (stable identifier, persists through amends/rebases): use for revsets and agent interaction.
   - `Commit ID` (Git SHA-1/SHA-256 hash): changes on every modification.

---

## 2. Revset Reference (Essential for Revision Targeting)

Pass revsets to `-r` or positional arguments to select commits without ambiguity:

| Revset Syntax | Meaning                                       | Example / Purpose                            |
| :------------ | :-------------------------------------------- | :------------------------------------------- |
| `@`           | Working copy revision                         | Current state being modified                 |
| `@-`          | Parent of the working copy                    | Commit just completed                        |
| `@+`          | Child of the working copy                     | Descendant revision                          |
| `x-` / `x+`   | Parents / Children of revision `x`            | `main-` (parent of main)                     |
| `::x`         | Ancestors of `x` (inclusive)                  | Equivalent to `root()::x`                    |
| `x::`         | Descendants of `x` (inclusive)                | All commits based on `x`                     |
| `x::y`        | DAG range from `x` to `y`                     | Descendants of `x` that are ancestors of `y` |
| `x..y`        | Git-style range (`::y ~ ::x`)                 | Ancestors of `y` not in `x`                  |
| `x \| y`      | Union (OR)                                    | `feat1 \| feat2` (**Never** use commas)      |
| `x & y`       | Intersection (AND)                            | `trunk() & heads(all())`                     |
| `~x`          | Complement (NOT)                              | All revisions except `x`                     |
| `trunk()`     | Remote main branch                            | Usually alias for `main@origin`              |
| `conflict()`  | All visible commits with unresolved conflicts | Filter broken commits                        |
| `empty()`     | Commits with no diff against parents          | Detect redundant changes                     |

---

## 3. Standard Non-Interactive Workflows

### A. Inspect State & Diffs

```bash
# General status (shows @, parent @-, conflicts, and untracked changes)
jj status

# Inspect working copy changes
jj diff

# Inspect diff of a specific past revision
jj diff -r <change-id>

# Compact log of current stack up to trunk
jj log -r "trunk()..@ | @"
```

### B. Daily Development Cycle (Create -> Edit -> Commit)

In Jujutsu, `@` is always an active draft commit. You don't "stage and commit"; you edit files, set a message, and open a new draft on top:

```bash
# 1. Start work from trunk/main
jj new trunk() -m "feat(api): add auth endpoints"

# 2. (Agent writes/edits code in files...)

# 3. Finalize the change description (if not set in jj new)
jj describe -m "feat(api): implement JWT validation logic"

# 4. Close the commit by opening a clean working copy on top
jj new -m "chore: next task"
```

### C. Amending or Editing a Historical Commit

```bash
# Option 1: Move specific file modifications from @ into an ancestor:
jj squash --into <change-id> path/to/file.ext

# Option 2: Absorb changes automatically into the stack commits that touched those lines:
jj absorb

# Option 3: Switch working copy directly to the target commit to do refactoring:
jj edit <change-id>
# (Make file adjustments...)
# Switch back to the tip of your stack:
jj new <stack-tip-id>
```

### D. Splitting Changes Non-Interactively

Do NOT run bare `jj split`. To split files cleanly without launching a diff editor:

```bash
# Creates a new parent commit containing ONLY the specified paths,
# leaving all other modifications in the current working copy (@)
jj split path/to/file1.js path/to/file2.js -m "feat(core): extract base components"
```

### E. Bookmarks & Remote Synchronization (Git Interop)

Bookmarks correspond to Git branches. They do **not** auto-advance on `jj new`:

```bash
# Create/move a bookmark pointing to the completed commit (@-)
jj bookmark set feature-auth -r @-

# Fetch remote refs
jj git fetch

# Track remote bookmark if newly created
jj bookmark track feature-auth@origin

# Push bookmark to remote (equivalent to git push -u origin feature-auth)
jj git push --bookmark feature-auth
```

### F. Rebasing Stacks

```bash
# Rebase the entire current stack onto the updated trunk
jj rebase -s <stack-root-id> -d trunk()

# Rebase ONLY a single revision (leaving its children where they are)
jj rebase -r <change-id> -d <target-destination>
```

---

## 4. Conflict Handling Protocol for Agents

Conflicts do NOT stop, block, or abort commands. Jujutsu records conflict states inside the commit tree.

1. **Detection**:
   Check if the commit has conflicts:

   ```bash
   jj status
   # Look for: "There are unresolved conflicts at these paths:"
   ```

2. **Resolution Method (Non-Interactive File Editing)**:
   - Jujutsu writes standard conflict markers (`<<<<<<<`, `|||||||`, `>>>>>>>`) directly into the affected files in your working copy.
   - Use file reading and editing tools to parse the conflicted files, resolve markers, and write the clean content.
   - Once saved without markers, Jujutsu **automatically detects the resolution**. No staging command is needed.

3. **Resolution Method (Wholesale Source Selection)**:
   To overwrite conflicted paths completely using a known valid revision:
   ```bash
   jj restore --from <source-revision> path/to/conflicted-file.ext
   ```

---

## 5. Recovery & Error Handling ("Undo Engine")

Every mutating command records an atomic entry in the operations log.

- **Revert the last mistake immediately**:
  ```bash
  jj undo
  ```
- **Inspect the operations log**:
  ```bash
  jj op log --limit 5
  ```
- **Restore repo state to a specific operation ID**:
  ```bash
  jj op undo <operation-id>
  ```
- **Discard an unwanted change/draft**:
  ```bash
  # Abandons the specified commit and automatically rebases its children onto its parent
  jj abandon <change-id>
  ```

---

## 6. Machine Parsing & Extraction Snippets

For scripts or sub-agents needing deterministic string outputs:

```bash
# Get full Git commit hash for @
jj log --no-graph -T "commit_id" -r @

# Get Change ID for @
jj log --no-graph -T "change_id" -r @

# Check if working copy has changes (returns 1 if diff exists, 0 if clean)
jj diff --quiet

# List files modified in @
jj diff --summary -r @
```

---

## 7. Anti-Patterns & Common Pitfalls

| ❌ Invalid / Risky Pattern | ✅ Recommended Jujutsu Pattern   | Reason                                                          |
| :------------------------- | :------------------------------- | :-------------------------------------------------------------- |
| `git commit -m "..."`      | `jj describe -m "..." && jj new` | Git mutations bypass Jujutsu state tracking.                    |
| `jj describe` (bare)       | `jj describe -m "message"`       | Bare describe launches an interactive `$EDITOR`.                |
| `jj split` (bare)          | `jj split <paths> -m "msg"`      | Bare split launches interactive diff UI.                        |
| `@~1` or `HEAD~`           | `@-`                             | Git syntax for parents is invalid in jj revsets.                |
| `a, b` for revset union    | `a \| b`                         | Comma is not an OR operator in revsets.                         |
| `jj checkout <id>`         | `jj edit <id>` or `jj new <id>`  | `checkout` is deprecated/aliased; explicit intent is preferred. |
| `git push origin head`     | `jj git push --bookmark <name>`  | Bookmarks must be explicitly targeted for Git pushing.          |
