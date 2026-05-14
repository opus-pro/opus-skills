# Install on Codex CLI and Codex App

Both Codex CLI and Codex App share `~/.codex/config.toml` and read the same plugin marketplaces, so a single install works for both.

## One command

```bash
codex plugin marketplace add github:opus-pro/opus-skills
```

Then inside the Codex TUI:

```
/plugins
```

Select `opusclip` → Install. The skill is discovered at `skills/opusclip/SKILL.md` and drives the OpusClip REST API via the bundled bash CLI at `scripts/opusclip`.

Codex reads `.claude-plugin/marketplace.json` natively (documented at <https://developers.openai.com/codex/plugins/build>), so no separate Codex-format marketplace file is needed.

## Codex App click-path

1. Open Codex App
2. Settings (Cmd+,) → **Plugins** to install from a marketplace
3. After install, the skill triggers on phrases like "clip this video"

## Configure

Set `OPUSCLIP_API_KEY` in the shell that launches Codex (or in `~/.codex/config.toml`'s env block). Get a key from <https://clip.opus.pro/dashboard>.

## Update

```bash
codex plugin marketplace upgrade
```
