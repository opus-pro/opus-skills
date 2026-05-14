# opus-skills

A skill marketplace for [OpusClip](https://opus.pro) — add video clipping, social posting, and more to your AI coding agent. Ships a SKILL.md the model auto-invokes, backed by a bash CLI wrapping the OpusClip REST API.

> A hosted HTTP MCP server is planned for cloud-chat hosts (Claude.ai, Cowork, Desktop) at `https://mcp.opus.pro/mcp`. Until then this is skill-only. The MCP server source lives in [`mcp-server/`](mcp-server/) for that future deployment.

## Install

| Agent | Install path |
|---|---|
| **Claude Code** | `/plugin marketplace add opus-pro/opus-skills` then `/plugin install opusclip@opus-skills` — see [docs/install/claude-code.md](docs/install/claude-code.md) |
| **Codex CLI / Codex App** | `codex plugin marketplace add github:opus-pro/opus-skills` then `/plugins` in TUI — see [docs/install/codex.md](docs/install/codex.md) |
| **Claude.ai** | Upload SKILL.md zip — see [docs/install/claude-ai.md](docs/install/claude-ai.md) |
| **Claude Cowork** | Same as Claude.ai — see [docs/install/cowork.md](docs/install/cowork.md) |
| **OpenClaw** | `openclaw plugins install github:opus-pro/opus-skills/skills/opusclip` — see [docs/install/openclaw.md](docs/install/openclaw.md) |
| **Any agent with `npx skills`** | `npx skills add opus-pro/opus-skills` |

## What's in the box

- **Skill** at `skills/opusclip/SKILL.md` — tells the model when and how to call OpusClip. Auto-triggers on phrases like "clip this video", "make shorts", "post to YouTube".
- **Bash CLI** at `skills/opusclip/scripts/opusclip` — the skill's execution path. Wraps the OpusClip REST API plus ffmpeg-based local utilities (`storyboard`, `trim`, `preview`).
- **Reference docs** at `skills/opusclip/references/api-reference.md`.

## Prerequisites

- `OPUSCLIP_API_KEY` — from <https://clip.opus.pro/dashboard>. API access requires an [Enterprise plan](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus).
- `curl` and `jq` on PATH. `ffmpeg` is also needed for `storyboard` and `trim`.

## Layout

```
opus-skills/
├── .claude-plugin/marketplace.json      # marketplace — read by Claude Code, Codex, OpenClaw
├── skills/opusclip/                     # the skill (also the plugin root)
│   ├── .claude-plugin/plugin.json       # Claude Code manifest
│   ├── .codex-plugin/plugin.json        # Codex manifest (adds `interface` for marketplace polish)
│   ├── SKILL.md
│   ├── scripts/opusclip                 # bash CLI
│   ├── templates/preview.html           # HTML preview template
│   └── references/api-reference.md
├── mcp-server/                          # MCP server source (TS) — reserved for future hosted HTTP deployment
└── docs/install/                        # per-agent install guides
```

## Develop

```bash
git clone https://github.com/opus-pro/opus-skills.git
cd opus-skills

# Run the bash CLI directly
export OPUSCLIP_API_KEY=sk_...
skills/opusclip/scripts/opusclip submit --url "https://youtube.com/watch?v=..."

# MCP server source (not active today; kept for future hosted HTTP deployment)
cd mcp-server
npm install && npm run build
OPUSCLIP_API_KEY=... npm start            # stdio
OPUSCLIP_API_URL=... npm run start:http   # HTTP (PORT=3000, path=/mcp)
```

## Contributing

CODEOWNERS lists current maintainers. Open a PR; CI runs eval on the skill against a fixed scenario set.

## License

MIT — see [LICENSE](LICENSE).
