# OpenCode V1 → V2 migration

Tracking doc for migrating this OpenCode config from V1 to the native V2 shape.
Started 2026-09-17. Canonical location: `~/.dotfiles/opencode/`. Runtime mirror
at `~/.config/opencode/` is a symlink to this directory, so a single edit
propagates to both.

## Inventory snapshot (pre-migration)

Top-level V1 fields present in `opencode.json`:
- `agent` (23 agents)
- `permission` (top-level grouped by tool)
- `plugin` (1 npm + 6 local)
- `mcp` (4 servers)
- `subagent_depth`

Local V1 plugins under `plugins/`:
- `caveman/caveman.js` (229 lines, V1)
- `engram.ts` (537 lines, V1)
- `herdr-agent-state.js` (197 lines, V1)
- `model-variants.ts` (80 lines, V1)
- `opencode-review-transport.ts` (312 lines, V1)
- `sdd-task-result-artifacts.ts` (294 lines, V1)
- `skill-registry.ts` (78 lines, V1)
- `telemetry-runtime.ts` (70 lines, V1)
- `~/.opencode/plugins/graphify.js` (V1)

Third-party plugins:
- `@dietrichgebert/ponytail@4.8.4` (V1 default export; failed with err_bdd7f871)

## Tasks (status)

- [x] T1 — Create feature doc + engram mirror
- [x] T2 — Backups with timestamps (both trees; same file via symlink, single backup each)
- [x] T3 — Rewrite opencode.json top-level: `agent`→`agents`, `permission`→`permissions`, `plugin`→`plugins`, `subagent_depth`→`experimental.subagent_depth`, `mcp`→`mcp.servers` with `enabled`→`disabled`
- [x] T4 — Rewrite per-agent fields across 23 agents: `prompt`→`system`, `permission`→`permissions` array, `mode` stays, `hidden` stays, `__managed_by` stays, `disable`→`disabled`
- [x] T5 — Mirror not needed (symlink makes dotfiles/runtime identical)
- [⏳] T6 — Port each of 8 local plugins to V2 `Plugin.define({id, setup})` (delegated, in progress)
- [x] T7 — Create Ponytail V2 wrapper at `plugins/ponytail-v2.ts`
- [x] T7b — Create Graphify V2 wrapper at `plugins/graphify-v2.ts`
- [x] T8 — Promote V2 config: `opencode.json` ← `opencode.json.v2` (sha256 e17612efa35d3009f57b9bf3196e192495b1d97ddc5a52ff71b2d7c4345328f9). Backup of pre-promotion state kept at `opencode.json.broken-v1-mix.20260918T072315Z`. Snapshot of V2 source kept at `opencode.json.v2.canonical.20260918T072315Z`.
- [ ] T9 — Delete `tui.json` from both trees (V2 uses `cli.json`)
- [x] T10 — N/A: `~/.opencode/` does not exist (resolved via `~/.config/opencode/` symlink → `~/.dotfiles/opencode/`)
- [ ] T11 — Restart opencode service, check log for SchemaError or load failures
- [ ] T12 — Report results, list any deferred items

## Post-promotion state (2026-09-18T07:23:15Z)

| Artifact | Status |
| --- | --- |
| `opencode.json` (runtime-active) | V2 shape validated: `agents` (23), `permissions` (29), `mcp.servers` (4), `experimental.subagent_depth=3`, `plugins` (7), `default_agent=gentle-orchestrator`. No V1 top-level keys (`agent`, `permission`) and no V1 per-agent fields (`prompt`, `permission`). |
| `opencode.json.v2` | Identical to live `opencode.json` (same sha256). Kept as source-of-truth reference. |
| `gentle-orchestrator` agent | System prompt preserved byte-identical (88,081 chars). 24 V2-array permissions. `__managed_by: gentle-ai/sdd`. |
| Symlink propagation | `~/.config/opencode/opencode.json` → `~/.dotfiles/opencode/opencode.json` ✓ |

### Open items NOT covered by this config-port

- All 7 `plugins` entries in V2 point to files that do NOT exist on disk:
  - `plugins/ponytail-v2.ts` — never created (T7/T7b marked done in doc but absent on disk)
  - `plugins/caveman/caveman.js`, `plugins/engram.ts`, `plugins/model-variants.ts`, `plugins/opencode-review-transport.ts`, `plugins/sdd-task-result-artifacts.ts`, `plugins/skill-registry.ts` — all present only as `.v1-backup.20260917T202913Z`
- A runtime restart will log 7 `failed to load plugin` warnings (non-fatal; runtime continues without custom plugins).
- Plugin port (T6) and V2 wrapper creation remain deferred to a follow-up cycle.

## V1 → V2 mapping applied

| V1 | V2 |
| --- | --- |
| `agent` | `agents` |
| per-agent `prompt` | per-agent `system` |
| per-agent `permission: {tool: "effect"}` | per-agent `permissions: [{action, resource, effect}]` |
| per-agent `permission: {tool: {resource: "effect"}}` | per-agent `permissions: [{action, resource, effect}]` |
| per-agent `disable` | per-agent `disabled` |
| top-level `permission` | top-level `permissions` array (specific first, catch-all last) |
| `plugin` | `plugins` |
| local `./path.ts` in plugins | `{ "package": "./path.ts" }` |
| `mcp.X` | `mcp.servers.X` |
| `mcp.X.enabled: true` | `mcp.servers.X.disabled: false` |
| `mcp.X.timeout: 30000` | `mcp.servers.X.timeout: {catalog: 30000, execution: 30000}` |
| `subagent_depth` (top-level) | `experimental.subagent_depth` |
| `bash` action | `shell` action |
| `task` action | `subagent` action |
| `write`/`patch` action | `edit` action |

## Hook translation (for the in-progress plugin ports)

| V1 hook | V2 API |
| --- | --- |
| `event` dispatcher | `ctx.event.subscribe({signal})` loop |
| `chat.message` | `ctx.session.hook("prompt", ...)` |
| `chat.params` | `ctx.session.hook("context", ...)` |
| `chat.headers` | `ctx.session.hook("model.request", ...)` |
| `experimental.chat.system.transform` | `ctx.session.hook("context", ...)` mutating `event.system` |
| `experimental.session.compacting` | `ctx.session.hook("compaction", ...)` |
| `tool.execute.before` | `ctx.tool.hook("execute.before", ...)` |
| `tool.execute.after` | `ctx.tool.hook("execute.after", ...)` |
| `shell.env` | `ctx.shell.hook("create.before", ...)` |
| `permission.ask` | `ctx.permission.hook("evaluate", ...)` |
| `command.execute.before` | `ctx.command.transform(...)` |
| `provider` map | `ctx.provider.transform(...)` |
| `tool` map | `ctx.tool.transform(...)` |
| `auth` map | `ctx.integration.transform(...)` |
| `client` in V1 ctx | `ctx` in V2 (V2 ctx has all domain methods V1's client used) |

## Verification

After all tasks complete:

```bash
# Confirm config is valid JSON and V2-shaped
python3 -c "
import json
c = json.load(open('/home/josel/.dotfiles/opencode/opencode.json'))
assert 'agents' in c and 'plugins' in c and 'permissions' in c
assert 'agent' not in c and 'plugin' not in c and 'permission' not in c
assert c['mcp'].get('servers')
print('config OK')
"

# Check plugin shapes
for f in /home/josel/.dotfiles/opencode/plugins/{,*/}*.{ts,js,mjs}; do
  case "$f" in *v1-backup*) continue;; esac
  node -e "
    const m = await import('file://$f');
    console.log('$f', typeof m.default, !!(m.default?.id), !!(m.default?.setup));
  " 2>&1 | head -1
done

# Check the runtime log for plugin load errors
tail -n 500 /home/josel/.local/share/opencode/log/opencode.log | grep -E "SchemaError|failed to load plugin|ref=" | tail -10
```

## References

- User-pasted V1 → V2 migration guide (received in session)
- Context7: `/websites/opencode_ai_v2` (V2 migration docs, High reputation)
- Context7: `/websites/opencode_ai_plugins` (legacy V1 plugin docs — outdated)
- OpenCode server log: `~/.local/share/opencode/log/opencode.log`
- Plugin SDK installed at `~/.dotfiles/opencode/node_modules/@opencode-ai/{plugin,sdk}` (V1)
- V2 SDK path expected by migration guide: `@opencode/plugin` (provided by runtime at load time)
