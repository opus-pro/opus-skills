# opus-skills

A plugin marketplace for [OpusClip](https://opus.pro) — adds video clipping, social posting, and more to your AI coding agent. One plugin ships **a skill** (SKILL.md the model auto-invokes) and **an MCP server** (20 tools wrapping the OpusClip REST API).

## Install

| Agent | Install path |
|---|---|
| **Claude Code** | `/plugin marketplace add opus-pro/opus-skills` then `/plugin install opusclip@opus-skills` — see [docs/install/claude-code.md](docs/install/claude-code.md) |
| **Codex CLI / Codex App** | `codex plugin marketplace add github:opus-pro/opus-skills` then `/plugins` in TUI — see [docs/install/codex.md](docs/install/codex.md) |
| **Claude.ai** | Add Custom Connector + upload SKILL.md zip (manual, two steps) — see [docs/install/claude-ai.md](docs/install/claude-ai.md) |
| **Claude Cowork** | Same as Claude.ai (connectors propagate) — see [docs/install/cowork.md](docs/install/cowork.md) |
| **OpenClaw** | `openclaw plugins install github:opus-pro/opus-skills/plugins/opusclip` — see [docs/install/openclaw.md](docs/install/openclaw.md) |
| **Any agent with `npx skills`** | `npx skills add opus-pro/opus-skills` (skill only, no MCP) |

## What's in the box

- **Skill** at `plugins/opusclip/skills/opusclip/SKILL.md` — tells the model when and how to call OpusClip. Auto-triggers on phrases like "clip this video", "make shorts", "post to YouTube".
- **MCP server** at `plugins/opusclip/.mcp.json` → `npx -y @opus-pro/opusclip-mcp@latest` — 20 tools covering the OpusClip REST API: submit, list, describe, brand templates, project sharing, local upload, collections (6), censoring (2), and social posting (6).
- **Bash CLI fallback** at `plugins/opusclip/skills/opusclip/scripts/opusclip` — for agents without MCP, or for ffmpeg-based local utilities (`storyboard`, `trim`).
- **Reference docs** at `plugins/opusclip/skills/opusclip/references/api-reference.md`.

## Prerequisites

- `OPUSCLIP_API_KEY` — from <https://clip.opus.pro/dashboard>. API access requires an [Enterprise plan](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus).
- For Claude.ai / Cowork: a deployed HTTPS endpoint of the MCP server (the package supports it via `node dist/http.js` — hosted endpoint planned at `https://mcp.opus.pro/mcp`).

## Layout

```
opus-skills/
├── .claude-plugin/marketplace.json      # marketplace — read by Claude Code, Codex, OpenClaw
├── plugins/opusclip/                    # the plugin
│   ├── .claude-plugin/plugin.json       # Claude Code manifest
│   ├── .codex-plugin/plugin.json        # Codex manifest (adds `interface` for marketplace polish)
│   ├── .mcp.json                        # MCP server config (cross-agent)
│   └── skills/opusclip/
│       ├── SKILL.md
│       ├── scripts/opusclip             # bash CLI fallback
│       └── references/api-reference.md
├── mcp-server/                          # @opus-pro/opusclip-mcp source (TS)
└── docs/install/                        # per-agent install guides
```

## Develop

```bash
# Skill / plugin
git clone https://github.com/opus-pro/opus-skills.git
cd opus-skills

# MCP server
cd mcp-server
npm install && npm run build
OPUSCLIP_API_KEY=... npm start            # stdio
OPUSCLIP_API_URL=... npm run start:http   # HTTP (PORT=3000, path=/mcp)
```

## Contributing

CODEOWNERS lists current maintainers. Open a PR; CI runs eval on the skill against a fixed scenario set.

## License

MIT — see [LICENSE](LICENSE).
