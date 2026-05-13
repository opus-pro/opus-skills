# Changelog

## 2.0.0 — Plugin marketplace + MCP server

**Breaking — repo layout changed.** Re-install with `/plugin update opusclip@opus-skills` (Claude Code) or `codex plugin marketplace upgrade` (Codex). Skill-only `npx skills update` installs also need to be refreshed.

### Added
- **MCP server** at `mcp-server/` published as `@opus-pro/opusclip-mcp` on npm. 20 tools mirroring the bash CLI's API surface (`submit_video`, `list_clips`, `describe_clip`, `list_brand_templates`, `share_project`, `upload_local_video`, plus 6 collection, 2 censor, and 6 social-posting tools). stdio + HTTP entrypoints.
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
