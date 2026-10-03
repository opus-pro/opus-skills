# opus-skills

A skill marketplace for [OpusClip](https://opus.pro) — adds video clipping, social posting, and more to your AI coding agent. Ships a `SKILL.md` the model auto-invokes when the prompt looks OpusClip-shaped (e.g. "clip this video"), backed by a bundled bash CLI that drives the OpusClip REST API.

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

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

Then export your key (from <https://clip.opus.pro/dashboard>, Enterprise, Pro, or Max plan required) in the shell that launches your agent:

```bash
export OPUSCLIP_API_KEY=sk_...
```

`curl` and `jq` must be on PATH. `ffmpeg` is needed only for the optional `storyboard`, `trim`, and `preview` commands.

## What's in the box

- **`skills/opusclip/SKILL.md`** — when and how to call OpusClip. Triggers on "clip this video", "make shorts", "post to YouTube", etc.
- **`skills/opusclip/scripts/opusclip`** — bash CLI wrapping the OpusClip REST API + ffmpeg local utilities.
- **`skills/opusclip/references/api-reference.md`** — endpoint schemas, request/response shapes.

## Copy Video Style

`skills/copy-video-style/` is a standalone skill. Give your agent your footage, a reference video or link, and the aspects to borrow. It uses Gemini understanding through OpusClip MCP, checks the actual frames, then creates and reviews the video locally. It does not require a plugin install or an OpusClip editor project.

Install for your agent (Node.js and the agent must be available):

```bash
npx skills add opus-pro/opus-skills --skill copy-video-style --agent codex --global
# For Claude Code, replace codex with claude-code.
```

Connect MCP separately:

```bash
# Codex CLI/App
codex mcp add opusclip --url https://mcp.opus.pro/mcp
codex mcp login opusclip

# Claude Code
claude mcp add --transport http --scope user opusclip https://mcp.opus.pro/mcp
# Open Claude Code and run /mcp to authenticate OpusClip.
```

Complete OAuth sign-in and select your organization in the agent's connection flow. An API key for the existing clipping CLI does not authenticate this MCP connection. Restart the agent session after installing. Video understanding uses OpusClip credits; local editing uses your agent and local tools. The connected backend and account must expose `opusclip_analyze_media`. If it is absent or disabled, the agent must explain that limitation rather than claim Gemini ran.

Example request:

> Use copy-video-style with my footage and this reference. Borrow its caption treatment, pacing and framing, keep my message intact, and deliver a local MP4 plus an editable project.

## Develop

```bash
git clone https://github.com/opus-pro/opus-skills.git
cd opus-skills
export OPUSCLIP_API_KEY=sk_...
skills/opusclip/scripts/opusclip project create --url "https://youtube.com/watch?v=..."
```

## Contributing

CODEOWNERS lists current maintainers. Open a PR and a maintainer will review.

## License

MIT — see [LICENSE](LICENSE).
