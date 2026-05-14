# Changelog

## 2.1.0 — Pure-skill repo

Reverts the 2.0.0 plugin-marketplace + MCP changes. Back to the pre-2.0.0 shape: one skill at `skills/opusclip/` driving the OpusClip REST API via the bundled bash CLI.

- Drop the bundled stdio MCP server (`.mcp.json`, `mcp-server.mjs`, `mcp-server/` source) — duplicated what the bash CLI already does on the same hosts.
- Drop the `plugins/opusclip/` wrapper — only existed to host MCP config at a plugin root.
- Drop `docs/install/` — README install table + SKILL.md cover everything.
- Restore `skills/opusclip/templates/preview.html`; `opusclip preview` is no longer shipped-broken.
- `SKILL.md` is byte-identical to the 1.x eval-tuned baseline (19/19 from #12).
- `OPUSCLIP_API_KEY` access now also available on the Pro plan, not just Enterprise.

## 2.0.0 — Plugin marketplace + MCP server

**Breaking — repo layout changed.** Re-install with `/plugin update opusclip@opus-skills` (Claude Code) or `codex plugin marketplace upgrade` (Codex). Skill-only `npx skills update` installs also need to be refreshed.

### Added
- **MCP server** at `mcp-server/`, bundled with esbuild into a single self-contained file at `plugins/opusclip/mcp-server.mjs` and shipped inside the plugin (no npm publish — `.mcp.json` runs `node ${CLAUDE_PLUGIN_ROOT}/mcp-server.mjs`). 20 tools mirroring the bash CLI's API surface (`submit_video`, `list_clips`, `describe_clip`, `list_brand_templates`, `share_project`, `upload_local_video`, plus 6 collection, 2 censor, and 6 social-posting tools). stdio + HTTP entrypoints in source.
- **Codex plugin manifest** at `plugins/opusclip/.codex-plugin/plugin.json` with a rich `interface` block (displayName, logo, screenshots, capabilities) for marketplace presentation.
- **Per-agent install docs** under `docs/install/` for Claude Code, Codex CLI/App, Claude.ai, Claude Cowork, and OpenClaw.

### Changed
- **Repo layout**: skill moved from `skills/opusclip/` to `plugins/opusclip/skills/opusclip/` per Claude Code's plugin auto-discovery contract. Marketplace `source` updated accordingly.
- **MCP-first dispatch** in `SKILL.md`: model is instructed to prefer MCP tools when present, fall back to the bash CLI otherwise.
- **Bash CLI** version bumped to 2.0.0.

### Removed
- `opusclip preview` bash command (template file was deleted in a prior PR and the command was broken). MCP server does not expose a preview tool either — it's a UI helper, not an API call. Use `list_clips` to get preview URLs and embed them yourself.

## 1.3.0 — *2026-04-29*
- chore: bump version to 1.3.0

## 1.2.0 — *2026-04-26*
- fix: strip project prefix from composite clip IDs (#15)
- fix: `clipDurations` format — use `[[min,max]]` ranges, not flat array (#14)
- chore: bump version to 1.2.0 (#13)

## 1.1.0 — *2026-04-24*
- docs: improve skill based on eval results (15/19 → targeting 19/19) (#12)
