# opus-skills

A skill marketplace for [OpusClip](https://opus.pro) — adds video clipping, social posting, and more to your AI coding agent. Ships a `SKILL.md` the model auto-invokes when the prompt looks OpusClip-shaped (e.g. "clip this video"), backed by a bundled bash CLI that drives the OpusClip REST API.

## Install

**Install this skill: <https://github.com/opus-pro/opus-skills>**

Point your agent at the repo above and ask it to install the skill — most agents can fetch, zip, and wire it up from a URL. If yours needs a specific command, use the per-host shortcuts below.

<details>
<summary>Per-host install commands</summary>

| Agent | Command |
|---|---|
| **Claude Code** | `/plugin marketplace add opus-pro/opus-skills` then `/plugin install opusclip@opus-skills` |
| **Codex CLI / App** | `codex plugin marketplace add github:opus-pro/opus-skills`, then **Plugins** in TUI/App |
| **OpenClaw** | `openclaw plugins install github:opus-pro/opus-skills/skills/opusclip` |
| **Claude.ai** | Download the repo, then `cd skills && zip -r opusclip-skill.zip opusclip` → upload at Settings → Customize → Skills (Pro+) |
| **Claude Cowork** | Same zip upload as Claude.ai (propagates to Cowork) |
| **Any host with `npx skills`** | `npx skills add opus-pro/opus-skills` |

</details>

Then export your key (from <https://clip.opus.pro/dashboard>, Enterprise or Pro plan required) in the shell that launches your agent:

```bash
export OPUSCLIP_API_KEY=sk_...
```

`curl` and `jq` must be on PATH. `ffmpeg` is needed only for the optional `storyboard`, `trim`, and `preview` commands.

## What's in the box

- **`skills/opusclip/SKILL.md`** — when and how to call OpusClip. Triggers on "clip this video", "make shorts", "post to YouTube", etc.
- **`skills/opusclip/scripts/opusclip`** — bash CLI wrapping the OpusClip REST API + ffmpeg local utilities.
- **`skills/opusclip/references/api-reference.md`** — endpoint schemas, request/response shapes.

## Develop

```bash
git clone https://github.com/opus-pro/opus-skills.git
cd opus-skills
export OPUSCLIP_API_KEY=sk_...
skills/opusclip/scripts/opusclip submit --url "https://youtube.com/watch?v=..."
```

## Contributing

CODEOWNERS lists current maintainers. Open a PR; CI runs eval on the skill against a fixed scenario set.

## License

MIT — see [LICENSE](LICENSE).
