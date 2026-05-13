# Install on Claude.ai

Claude.ai requires two manual steps (no GitHub-repo one-click install). Pro / Max / Team / Enterprise plan needed.

## Step 1 — Add the MCP server as a Custom Connector

Claude.ai only talks to MCP servers over public HTTPS. The OpusClip MCP server has an HTTP entrypoint deployed at `https://mcp.opus.pro/mcp` (*not yet live as of 2026-05 — see hosting note below*).

1. Open <https://claude.ai>
2. Settings → **Connectors** → **Add custom connector**
3. URL: `https://mcp.opus.pro/mcp`
4. Auth: **Bearer token** — paste your `OPUSCLIP_API_KEY` from <https://clip.opus.pro/dashboard>
5. Save

Verify by clicking the tools picker in any chat — `opusclip` should be listed with 20 tools.

## Step 2 — Upload the skill (optional)

The skill is a SKILL.md + supporting files. It's optional — the MCP server alone is functional — but the skill adds the triggering logic that tells Claude *when* to reach for the OpusClip tools.

1. From this repo, zip the skill folder:
   ```bash
   cd plugins/opusclip/skills && zip -r opusclip-skill.zip opusclip
   ```
2. Open <https://claude.ai> → Settings → **Customize** → **Skills**
3. Click **+** → upload `opusclip-skill.zip`

`upload_local_video` won't work — the hosted MCP server doesn't have access to your local filesystem. Use `submit_video` with a public URL instead.

## Hosting note

`https://mcp.opus.pro/mcp` is the planned hosted endpoint. Until it's deployed, Claude.ai cannot connect to this MCP server (stdio-only doesn't work on the web). Self-hosting: the HTTP entrypoint is in `mcp-server/src/http.ts` — `node dist/http.js` listens on `PORT` (default 3000) at path `/mcp`.

## Plan / permission requirements

| Feature | Required plan |
|---|---|
| Custom connectors | Pro, Max, Team, Enterprise |
| Skill upload (with code execution) | Pro, Max, Team, Enterprise |
| Org-wide skill provisioning | Team, Enterprise |
