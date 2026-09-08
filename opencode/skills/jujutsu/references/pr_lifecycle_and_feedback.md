# Scenario: Pull Request Lifecycle & Review Feedback Handling

## Context & Goal

Manage remote Git bookmarks, publish individual or chained Pull Requests via GitHub CLI (`gh`), and update existing PRs after code review modifications using Jujutsu's native rewriting capabilities.

## Execution Trace

### 1. Assign Bookmarks to Stacked Commits

```bash
# Given a 2-commit stack: @- (backend) and @ (frontend)
BACKEND_REV=$(jj log --no-graph -T "change_id" -r "@-")
FRONTEND_REV=$(jj log --no-graph -T "change_id" -r "@")

# Assign bookmarks (Git branch equivalents)
jj bookmark set feat-user-backend -r "$BACKEND_REV"
jj bookmark set feat-user-frontend -r "$FRONTEND_REV"
```

### 2. Push Bookmarks to Remote

```bash
# Track and push bookmarks cleanly
jj git push --bookmark feat-user-backend
jj git push --bookmark feat-user-frontend
```

### 3. Open Stacked Pull Requests via GitHub CLI

```bash
# Open Base PR targeting main
gh pr create --head feat-user-backend --base main --title "feat(api): user backend endpoints" --body "Part 1 of user feature stack."

# Open Dependent PR targeting the backend branch
gh pr create --head feat-user-frontend --base feat-user-backend --title "feat(ui): user profile screen" --body "Part 2 of user feature stack. Depends on #<base_pr_number>."
```

### 4. Address Review Feedback on the Base PR

Requirement: Reviewer requests changes on `feat-user-backend`. The agent must update the backend commit without destroying the frontend commit built on top of it.

```bash
# Option A: Targeted file edit directly from top of stack using squash
# (Agent edits src/controllers/user.rs while sitting on working copy...)
jj squash --into feat-user-backend src/controllers/user.rs

# Option B: Direct jump to the bookmark
jj edit feat-user-backend
# (Agent makes review fixes...)
# Return to the tip of frontend
jj edit feat-user-frontend

# Force-push updated bookmarks (jj handles rewriting and update safely)
jj git push --bookmark feat-user-backend
jj git push --bookmark feat-user-frontend
```

## Invariant Assertions

```bash
# 1. Verify bookmarks point to the expected changes
jj bookmark list

# 2. Verify local bookmarks match remote tracking markers
jj log -r "feat-user-backend | feat-user-backend@origin"
```

## Failure Modes & Recovery

- **Rejected push due to non-fast-forward on remote:** Run `jj git fetch` followed by `jj rebase -d feat-user-backend@origin` before re-pushing.
- **Accidental bookmark movement:** If a bookmark was set to the wrong revision, move it back deterministically: `jj bookmark set <name> -r <exact-change-id>`.
