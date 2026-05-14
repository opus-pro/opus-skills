# Install on OpenClaw

OpenClaw is a self-hosted personal AI agent that reads SKILL.md files in standard format.

## Option A — Plugin install (one command)

```bash
openclaw plugins install github:opus-pro/opus-skills/skills/opusclip
```

OpenClaw reads `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` via its compat layer. The skill auto-discovers from `skills/opusclip/SKILL.md` inside the plugin and drives the OpusClip REST API via the bundled bash CLI at `scripts/opusclip`.

## Option B — Skill-only via the skills CLI

```bash
npx skills add opus-pro/opus-skills -a openclaw
```

This installs the skill into `~/.openclaw/skills/opusclip/`. Same skill, same bash CLI, just a different fetch path.

## Configure

Set `OPUSCLIP_API_KEY` in the shell that launches OpenClaw. Get a key from <https://clip.opus.pro/dashboard>.

## Update

```bash
openclaw plugins update opusclip
# or, for skill-only installs:
npx skills update opusclip
```
