---
name: search-tooling
description: >
  Trigger when subagent invokes CLI search tools (rg, fd, find, grep, ls, cat). Enforces bare-name path discipline + rg/fd preference over grep/find.
---

# Search tooling

## Activation

Trigger when a subagent (`code-flow-analyst`, `qa-doctor`, `fixer`) needs to read or search the codebase via bash. Applies to every CLI invocation that touches the filesystem tree.

## Hard Rules

- **Bare names only.** Invoke `rg`, `fd`, `cargo`, `uv`, `bun`, `node`, `pnpm`, `npm`, `clippy` by bare command name. **NEVER** prefix with absolute paths (`/usr/bin/rg`, `~/.local/bin/uv`, `$HOME/.cargo/bin/cargo`). The shell's `$PATH` is authoritative.
- **`command -v` for discovery only.** Use `command -v <tool>` to report what is installed. Use the bare name when actually invoking.
- **Prefer `rg` over `grep`, `fd` over `find`.** Both recursive by default, respect `.gitignore`, use PCRE2/regex patterns instead of `-name`. Fall back to grep/find only if `rg`/`fd` unavailable.
- Detect both with `command -v fd rg` alongside other tools in the sniff.

## Decision Gates

| Situation                                       | Action                                                  |
| ----------------------------------------------- | ------------------------------------------------------- |
| Need recursive regex search                     | `rg '<pattern>' <path>`                                 |
| Need to find files by name/regex                | `fd '<regex>' <path>`                                   |
| Need to read a single file's contents           | `cat <path>` (or `head`/`tail` for large files)         |
| Tool is missing                                 | fall back: `grep` for `rg`, `find -name` for `fd`       |
| Search across multiple paths in parallel        | `rg --multiline -l <p1> -l <p2>` (no xargs needed)      |

## Steps

1. Sniff installed tools: `command -v rg fd`.
2. Pick `rg`/`fd` if available, else grep/find.
3. Invoke by bare name. No path prefixes.
4. Pass paths as args, never absolute path prefixes.

## Output Contract

- One bash invocation per search query.
- Bare command name + arguments only.
- Exit code 0 (match) or 1 (no match); never silent failure.

## References

- `code-flow-analyst.md` §Faster search tools + §Path discipline (verbatim source).
- `qa-doctor.md` §Faster search tools.
- `fixer.md` §Faster search tools + §Path discipline.
- `~/.dotfiles/opencode/agents/` for subagent permission allowlists.