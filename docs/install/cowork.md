# Install on Claude Cowork

Cowork is the Anthropic-official desktop AI agent (macOS, Windows) on the Team / Enterprise plan. It shares the Claude.ai connector + skill model.

## Step 1 — Add the MCP server as a Custom Connector

Same flow as Claude.ai (see [claude-ai.md](claude-ai.md)). Custom connectors configured on your claude.ai account propagate to Cowork.

1. <https://claude.ai> → Settings → **Connectors** → **Add custom connector**
2. URL: `https://mcp.opus.pro/mcp` (see hosting note in [claude-ai.md](claude-ai.md))
3. Auth: Bearer token — paste your `OPUSCLIP_API_KEY`
4. Save — the connector becomes available in Cowork automatically

## Step 2 — Upload the skill (optional)

Same `.zip` upload as Claude.ai. Skills uploaded at <https://claude.ai> appear in Cowork too.

## Cowork-specific advantage

Cowork has **local filesystem access** (unlike Claude.ai web). So `upload_local_video` *could* work — but the MCP server is still remote, and the remote server can't read your local files. To upload a local video from Cowork, drag it into a public bucket first (or use the bash CLI inside Cowork's terminal: `scripts/opusclip upload --file ...`).

## Plan requirements

Cowork is Team or Enterprise only. Role-based access controls (Enterprise) let admins lock or pre-approve which connectors and skills are available to seats.
