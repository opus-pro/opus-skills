# Changelog

## 2.1.0 — Skill-only plugin (MCP set aside for hosted future)

The bundled stdio MCP server (introduced in 2.0.0) only worked on hosts that already have shell access — exactly the hosts where the bash CLI also works. It didn't unlock any audience the skill couldn't already serve, and it added a maintenance lane (drift between MCP tools and bash commands) plus an extra install-failure mode. So this release **removes the MCP from the plugin** and lets the skill drive the OpusClip REST API via the bundled bash CLI alone. The skill's eval went 15/19 → 19/19 in 1.1.0 on the bash CLI path; that's the path that ships.

The `mcp-server/` source stays in the repo. The plan is to deploy it as a hosted HTTPS MCP at `https://mcp.opus.pro/mcp` so cloud-chat hosts (Claude.ai, Cowork, Desktop) can connect via Custom Connector — that's the "real MCP" this work is reserved for. When that endpoint is live, a future release will re-introduce `.mcp.json` pointing at the URL.

### Removed
- `plugins/opusclip/.mcp.json` — MCP server config.
- `plugins/opusclip/mcp-server.mjs` — bundled stdio MCP server JS.
- MCP-aware sections of `SKILL.md` (tool dispatch, MCP tool table, MCP tool argument shapes).

### Restored
- `plugins/opusclip/skills/opusclip/templates/preview.html` — the 2.0.0 marketplace rebase deleted this template but kept the bash `cmd_preview` function + dispatch, leaving `opusclip preview` broken with "template not found". Template is back; `opusclip preview --project ID` works again.
- `SKILL.md` is now byte-identical to the 1.x eval-tuned baseline (`ee122a9`, the 19/19 version from #12) — including the `### preview` subsection and the preview step in the "Clip a YouTube video" workflow.

### Changed
- README install table simplified — no more two-step Custom Connector + skill-upload for Claude.ai / Cowork. Skill upload is the one step.
- All `docs/install/*.md` updated to drop MCP setup.

### Kept
- `mcp-server/` source directory — reserved for the future hosted HTTP deployment.

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
