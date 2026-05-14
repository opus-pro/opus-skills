# Install on Claude Code

## One command

```
/plugin marketplace add opus-pro/opus-skills
/plugin install opusclip@opus-skills
```

`/plugin install` clones the plugin into `~/.claude/plugins/cache/opus-skills/opusclip/<version>/`, registers the skill (`SKILL.md` auto-discovered from `skills/opusclip/`), and starts the MCP server defined in `.mcp.json` — `node ${CLAUDE_PLUGIN_ROOT}/mcp-server.mjs`, the bundled JS that ships with the plugin (no `npx`, no external download).

## Configure

Export your OpusClip API key in the shell that launches Claude Code:

```bash
export OPUSCLIP_API_KEY=sk_...
```

The MCP server reads it from the environment. Get a key from <https://clip.opus.pro/dashboard> (Enterprise plan required).

## Verify

```
/mcp
```

Should list `opusclip` with 20 tools. Tool names are prefixed `mcp__plugin_opusclip_opusclip__<tool>` in the tool palette.

The skill triggers on phrases like "clip this video", "make shorts", "post to YouTube". Run `/help` to confirm `opusclip` is listed.

## Smoke test

> "Submit https://www.youtube.com/watch?v=dQw4w9WgXcQ to OpusClip."

The model should call `submit_video` and return a clip-project ID.

## Update

```
/plugin update opusclip@opus-skills
```

## Troubleshoot

- **MCP server not starting** — run Claude Code with `--debug`. The most common cause is `OPUSCLIP_API_KEY` not in the environment Claude Code inherits.
- **Node not on PATH** — `.mcp.json` runs the bundle with `node`. Node ≥18 must be available in the environment Claude Code launches from.
- **Tools not appearing** — `/plugin disable opusclip@opus-skills` then `/plugin enable opusclip@opus-skills` to re-register.
