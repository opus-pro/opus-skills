# opus-skills

A skill marketplace for [OpusClip](https://opus.pro) — adds video clipping, social posting, and more to your AI coding agent. The existing OpusClip package contains two skills: `opusclip` for clipping and publishing through the bundled API CLI, and `copy-video-style` for reference-driven local editing, with optional OpusClip MCP video understanding.

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

## Install

**Install OpusClip: <https://github.com/opus-pro/opus-skills>**

Point your agent at the repo above and ask it to install the skill — most agents can fetch, zip, and wire it up from a URL. If yours needs a specific command, use the per-host shortcuts below.

<details>
<summary>Per-host install commands</summary>

| Agent | Command |
|---|---|
| **Claude Code** | `/plugin marketplace add opus-pro/opus-skills` then `/plugin install opusclip@opus-skills` |
| **Codex CLI / App** | `codex plugin marketplace add github:opus-pro/opus-skills`, then **Plugins** in TUI/App |
| **OpenClaw** | `openclaw plugins install github:opus-pro/opus-skills/skills/opusclip` |
| **Claude.ai** | Upload one skill folder per ZIP: `skills/opusclip/` for clipping, or `skills/opusclip/skills/copy-video-style/` for local editing, at Settings → Customize → Skills (Pro+) |
| **Claude Cowork** | Same zip upload as Claude.ai (propagates to Cowork) |
| **Any host with `npx skills`** | `npx skills add opus-pro/opus-skills` |

</details>

For the clipping CLI, export your key (from <https://clip.opus.pro/dashboard>, Enterprise, Pro, or Max plan required) in the shell that launches your agent:

```bash
export OPUSCLIP_API_KEY=sk_...
```

`curl` and `jq` must be on PATH for the clipping CLI. Its optional `storyboard`, `trim`, and `preview` commands need `ffmpeg`. Copy Video Style needs a local renderer such as FFmpeg; styled captions need an FFmpeg build with libass and freetype (on macOS, Homebrew `ffmpeg-full`, which is keg-only, so the skill calls it by its full path), and linked references need `yt-dlp`.

## What's in the box

- **`skills/opusclip/SKILL.md`** — when and how to call OpusClip. Triggers on "clip this video", "make shorts", "post to YouTube", etc.
- **`skills/opusclip/scripts/opusclip`** — bash CLI wrapping the OpusClip REST API + ffmpeg local utilities.
- **`skills/opusclip/references/api-reference.md`** — endpoint schemas, request/response shapes.
- **`skills/opusclip/skills/copy-video-style/SKILL.md`** — reference-driven local editing, with optional video understanding through OpusClip MCP.

## Copy Video Style

Copy Video Style is a separate skill inside the existing OpusClip package, alongside the `opusclip` clipping skill. Both share one package installation; no additional plugin or marketplace is needed. Give your agent your footage and a reference video or link. It scans the reference's frames, cuts and loudness locally, shows you what defines the style, and asks once which elements to copy, whether to add OpusClip video understanding for a few credits, and where any missing music or other assets should come from. Then it creates and reviews the video locally. It does not require an OpusClip editor project.

Install or update the OpusClip package using the installation methods above. To install both skills directly (Node.js and the agent must be available):

```bash
npx --yes skills add opus-pro/opus-skills --skill opusclip copy-video-style --agent codex --global --yes
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

Complete OAuth sign-in and select your organization in the agent's connection flow. An API key for the existing clipping CLI does not authenticate this MCP connection. Restart the agent session after installing. Video understanding is optional and uses OpusClip credits; local editing uses your agent and local tools. The connected backend and account must expose `opusclip_analyze_reference_media`. If you choose understanding and authentication is required or expired, the agent should help you sign in and retry. If understanding stays unavailable, the agent explains the blocker and continues from its local scan, noting that sound and music were not analyzed.

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
