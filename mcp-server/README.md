# @opus-pro/opusclip-mcp

MCP server for the [OpusClip API](https://help.opus.pro/api-reference/overview). Wraps the same REST surface as the bundled bash CLI in a Model Context Protocol server so AI coding agents can call the tools natively.

## Install

```bash
npx -y @opus-pro/opusclip-mcp
```

Or via your agent's plugin marketplace (`opus-pro/opus-skills`).

## Configure

Set `OPUSCLIP_API_KEY` in the environment passed to the MCP server. API access requires an [Enterprise plan](https://www.opus.pro/pricing).

Optional:
- `OPUSCLIP_API_URL` — override the base URL (default `https://api.opus.pro/api`).
- `OPUSCLIP_EXTRA_HEADERS` — semicolon-separated extra headers, e.g. `X-Trace: 1;X-Foo: bar`.

## Modes

- **stdio** (default): `opusclip-mcp` — for local agents (Claude Code, Codex CLI/App, OpenClaw).
- **HTTP**: `node dist/http.js` — for hosted use (Claude.ai Custom Connector, Claude Cowork). Accepts `Authorization: Bearer <OPUSCLIP_API_KEY>` per request. Default port `3000`, path `/mcp`.

## Tools

20 tools mirroring the bash CLI's API surface — clip submission, listing, describing, brand templates, project sharing, local upload, collection management (6), profanity censoring (2), and social posting (6). Local-only ffmpeg utilities (`storyboard`, `trim`, `preview`) are kept in the bash CLI, not exposed via MCP.

## Develop

```bash
npm install
npm run build
OPUSCLIP_API_KEY=... npm start
```
