# Install on Codex CLI and Codex App

Both Codex CLI and Codex App share `~/.codex/config.toml` and read the same plugin marketplaces, so a single install works for both.

## One command (recommended)

```bash
codex plugin marketplace add github:opus-pro/opus-skills
```

Then inside the Codex TUI:

```
/plugins
```

Select `opusclip` → Install. The skill is discovered at `plugins/opusclip/skills/opusclip/SKILL.md` and the MCP server is configured from `plugins/opusclip/.mcp.json` (`npx -y @opus-pro/opusclip-mcp@latest`).

Codex reads `.claude-plugin/marketplace.json` natively (documented at <https://developers.openai.com/codex/plugins/build>), so no separate Codex-format marketplace file is needed.

## Manual MCP-only install (no plugin)

If you only want the MCP server without the skill, edit `~/.codex/config.toml`:

```toml
[mcp_servers.opusclip]
command = "npx"
args = ["-y", "@opus-pro/opusclip-mcp@latest"]
env = { OPUSCLIP_API_KEY = "sk_..." }
```

Then `/mcp` in the Codex TUI to verify it appears, or in Codex App: **Settings (Cmd+,) → MCP**.

## Codex App click-path

1. Open Codex App
2. Settings (Cmd+,) → **Plugins** to install from a marketplace, or **MCP** to add the server manually
3. After install, the skill triggers on phrases like "clip this video"; MCP tools appear in the tool palette

## Configure

Set `OPUSCLIP_API_KEY` either in `config.toml`'s `env` block (above) or in the shell that launches Codex. Get a key from <https://clip.opus.pro/dashboard>.

## Update

```bash
codex plugin marketplace upgrade
```

## Known issue

[openai/codex#17360](https://github.com/openai/codex/issues/17360): MCP servers installed via a plugin may not show in the Codex App **Settings → MCP** UI even though they register and work at runtime. Use `/mcp` in the TUI to confirm.
