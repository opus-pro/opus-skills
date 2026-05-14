# Install on Claude Cowork

Cowork is the Anthropic-official desktop AI agent (macOS, Windows) on the Team / Enterprise plan. It shares the Claude.ai skill model.

## Upload the skill

Same `.zip` upload as Claude.ai (see [claude-ai.md](claude-ai.md)). Skills uploaded at <https://claude.ai> appear in Cowork automatically.

## Configure

Set `OPUSCLIP_API_KEY` in the skill's environment, or have Claude export it in the code-execution session. Get a key from <https://clip.opus.pro/dashboard>.

## Cowork-specific advantage

Cowork has **local filesystem access** (unlike Claude.ai web), so the bash CLI's `opusclip upload --file PATH` works against your machine when Cowork runs the skill locally. For Claude.ai you'd need to use a public URL with `opusclip submit --url`.

## Future: hosted MCP

A hosted HTTP MCP server is planned at `https://mcp.opus.pro/mcp` and will register as a Custom Connector that propagates from <https://claude.ai> into Cowork. Until then, the skill is the integration.

## Plan requirements

Cowork is Team or Enterprise only. Role-based access controls (Enterprise) let admins lock or pre-approve which skills are available to seats.
