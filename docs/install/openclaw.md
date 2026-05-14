# Install on OpenClaw

OpenClaw is a self-hosted personal AI agent that reads SKILL.md files in standard format and supports MCP servers via its own config file.

## Option A — Plugin install (one command)

```bash
openclaw plugins install github:opus-pro/opus-skills/plugins/opusclip
```

OpenClaw reads `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` via its compat layer, so the bundled `.mcp.json` is picked up too. The skill auto-discovers from `skills/opusclip/SKILL.md` inside the plugin.

## Option B — Skill-only via the skills CLI

```bash
npx skills add opus-pro/opus-skills -a openclaw
```

This installs the skill into `~/.openclaw/skills/opusclip/`. It does **not** configure the MCP server.

## Option C — Manual MCP entry

If you used Option B (or just want stand-alone MCP), edit `~/.openclaw/openclaw.json`:

```json
{
  "mcpServers": {
    "opusclip": {
      "transport": "stdio",
      "command": "node",
      "args": ["/abs/path/to/opus-skills/plugins/opusclip/mcp-server.mjs"],
      "env": { "OPUSCLIP_API_KEY": "sk_..." }
    }
  }
}
```

Note: OpenClaw requires the `transport` field (`"stdio"` or `"http"`). After adding a new server, run `openclaw gateway restart`.

Then verify with `openclaw mcp` to list registered servers.

## Configure

Set `OPUSCLIP_API_KEY` in the `env` block above, or export it before running OpenClaw. Get a key from <https://clip.opus.pro/dashboard>.

## Update

```bash
openclaw plugins update opusclip
# or, for skill-only installs:
npx skills update opusclip
```
