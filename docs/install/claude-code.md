# Install on Claude Code

## One command

```
/plugin marketplace add opus-pro/opus-skills
/plugin install opusclip@opus-skills
```

`/plugin install` clones the plugin into `~/.claude/plugins/cache/opus-skills/opusclip/<version>/` and registers the skill (`SKILL.md` auto-discovered from `skills/opusclip/`). The skill drives the OpusClip REST API via the bundled bash CLI at `scripts/opusclip`.

## Configure

Export your OpusClip API key in the shell that launches Claude Code:

```bash
export OPUSCLIP_API_KEY=sk_...
```

The bash CLI reads it from the environment. Get a key from <https://clip.opus.pro/dashboard> (Enterprise plan required).

## Verify

Run `/help` to confirm `opusclip` is listed. The skill triggers on phrases like "clip this video", "make shorts", "post to YouTube".

## Smoke test

> "Submit https://www.youtube.com/watch?v=dQw4w9WgXcQ to OpusClip."

The model should run `opusclip submit --url ...` and return a clip-project ID.

## Update

```
/plugin update opusclip@opus-skills
```

## Troubleshoot

- **`OPUSCLIP_API_KEY` not picked up** — must be exported in the shell *before* launching Claude Code. Exporting it from inside a Claude Code Bash tool call only affects that subshell.
- **`curl` / `jq` / `ffmpeg` missing** — the bash CLI needs `curl` and `jq` on PATH; `ffmpeg` only for `storyboard` and `trim`.
- **Skill not triggering** — `/plugin disable opusclip@opus-skills` then `/plugin enable opusclip@opus-skills` to re-register.
