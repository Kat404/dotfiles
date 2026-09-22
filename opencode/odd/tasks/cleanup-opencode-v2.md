# Cleanup V1 residue in opencode.json (canonical V2 shape per official schema)

**Project**: opencode dotfiles
**Session**: ses_f4a77c436ffeWawWLLnfHUneGO
**Created**: 2026-09-18
**Scope**: Surgical cleanup of `/home/josel/.dotfiles/opencode/opencode.json`

## Objective

Remove V1 residue from `opencode.json` so only the canonical V2 shape (per the `$schema` URL the file itself declares: `https://opencode.ai/config.json`) remains.

## Problem

The current file mixes V1 and V2 shapes, producing a 502 KB hybrid that violates `additionalProperties: false` at the top level and per-agent level. The migration doc (`opencode-v2-migration.md`) was based on an outdated/wrong schema mapping (plural `agents`/`permissions`/`plugins`). The official schema the file declares uses **singular** shapes:

- Top-level: `agent` (singular), `permission` (singular), `plugin` (singular)
- Per-agent (`AgentConfig`): `prompt`, `permission`, `mode`, `disable`, `model`, etc.
- NOT in schema at top-level: `agents`, `permissions` (array), `theme`, `plugins`
- NOT in `AgentConfig`: `system`, `permissions` (array), `disabled`

## Why

- The OpenCode 2.x runtime log shows no SchemaError after sync, but the file is bloated ~2× and contains divergent content (gentle-orchestrator: prompt=88,081 chars vs system=88,681 chars — 600 chars of potentially-stale drift).
- The V1-shape `agent` block (singular) contains the FULL working content used by the runtime today (we run as gentle-orchestrator successfully). The V2-shape `agents` block is dead weight.

## Tasks

- [ ] **T1**: Backup current `opencode.json` to timestamped snapshot.
- [ ] **T2**: Read full schema `$defs` (`AgentConfig`, `PermissionConfig`, `McpLocalConfig`, `McpRemoteConfig`) — DONE in this session.
- [ ] **T3**: Cleanup script — parse JSONC, remove top-level `agents`/`permissions`/`theme`, remove per-agent `system`/`permissions`, fix MCP `disabled`→`enabled`.
- [ ] **T4**: Verify JSON parse + structural check against schema key allow-list.
- [ ] **T5**: Re-run `gentle-ai sync` and confirm 0 verification failures.
- [ ] **T6**: Confirm OpenCode still loads the new config (default_agent, MCP servers reachable).

## Schema authoritative reference (top-level allowed keys)

```
$schema, agent, attachment, autoshare, autoupdate, command, compaction,
default_agent, disabled_providers, enabled_providers, enterprise,
experimental, formatter, instructions, layout, logLevel, lsp, mcp, mode,
model, permission, plugin, provider, reference, references, server, share,
shell, skills, small_model, snapshot, subagent_depth, tool_output, tools,
username, watcher
```
`additionalProperties: false`

## Schema authoritative reference (AgentConfig)

```
color, description, disable, hidden, maxSteps, mode (enum subagent|primary|all),
model, options, permission (PermissionConfig), prompt, steps, temperature,
tools, top_p, variant
```

## Schema authoritative reference (McpLocalConfig / McpRemoteConfig)

```
Local:  command, cwd, enabled, environment, timeout, type
Remote: enabled, headers, oauth, timeout, type, url
```
NOT `disabled` — must be `enabled`.

## Acceptance criteria

1. File parses as valid JSON.
2. No top-level keys outside the schema's allow-list.
3. Each `agent.<name>` only has fields from the AgentConfig allow-list (plus the Gentle-internal `__managed_by` marker).
4. MCP servers use `enabled` (boolean), not `disabled`.
5. `gentle-ai sync` returns "no managed sync actions needed" or all checks pass.
6. `gentle-ai doctor` MCP servers still reachable.

## Risks

- The singular `agent` block per-agent `prompt` for gentle-orchestrator is 88,081 chars; the `system` field is 88,681 chars (600 longer). Keeping `prompt` per schema means dropping 600 chars of possible additions. The user can re-add after review.
- `__managed_by` marker is not in the schema but is likely needed by `gentle-ai sync` to identify managed sections. Will preserve it.
- Re-sync may rewrite the file again (gentle-ai sync preserves user content + adds managed pieces). If sync clobbers the cleanup, investigate which managed-component owns the plural `agents` block.

## Status: COMPLETED

## Outcome

- File cleaned: 502,111 → 165,783 bytes (67% reduction).
- Top-level keys reduced from 11 to 8, all schema-conformant:
  `$schema, agent, default_agent, formatter, lsp, mcp, permission, share`
- Per-agent: removed `system` and `permissions` (plural array) from all 23 agents; kept `prompt`, `permission`, `mode`, `__managed_by`, etc.
- MCP: `disabled: false` → `enabled: true` (3 servers inverted; engram already conformant).
- Symlink propagation verified (same inode 807799619 for both `.dotfiles/` and `.config/` paths).
- Schema validation: 0 unknown top-level keys.

## Known caveat (gentle-ai 3.3.0 bug)

Running `gentle-ai sync` after the cleanup will re-introduce the residue (plural `agents` block + top-level `theme`) because gentle's managed components emit non-schema shapes. The current on-disk state is the post-cleanup stable form. If gentle-ai sync runs, re-apply this cleanup afterwards.

Backups retained:
- `.backups/opencode.pre-cleanup.20260918T181944Z.json` (502,111 bytes) — original pre-cleanup state
- `.backups/opencode.gentle-reclobber.20260918T182741Z.json` (336,799 bytes) — gentle's re-emission for diff
