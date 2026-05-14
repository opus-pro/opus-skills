# Install on Claude.ai

Claude.ai needs the skill uploaded as a zip. Pro / Max / Team / Enterprise plan required for skill upload with code execution.

## Upload the skill

1. From this repo, zip the skill folder:
   ```bash
   cd plugins/opusclip/skills && zip -r opusclip-skill.zip opusclip
   ```
2. Open <https://claude.ai> → Settings → **Customize** → **Skills**
3. Click **+** → upload `opusclip-skill.zip`

## Configure

The skill calls the OpusClip REST API via its bundled bash CLI. Claude.ai's code-execution sandbox needs the API key in its environment — set `OPUSCLIP_API_KEY` in your skill's environment settings, or have Claude `export` it before the first call.

Get a key from <https://clip.opus.pro/dashboard> (Enterprise plan required for API access).

## Limitations

- **Local upload won't work.** The bash CLI's `opusclip upload --file PATH` reads from a host filesystem. Claude.ai's sandbox doesn't have access to your local machine — use `opusclip submit --url PUBLIC_URL` with a hosted video instead (YouTube, S3, etc.).
- **No tool palette.** Claude.ai surfaces the skill's bash CLI through code execution; you won't see typed MCP tools in the tool picker. A hosted HTTP MCP server is planned at `https://mcp.opus.pro/mcp` for a richer Claude.ai experience — until then, the skill is the integration.

## Plan / permission requirements

| Feature | Required plan |
|---|---|
| Skill upload (with code execution) | Pro, Max, Team, Enterprise |
| Org-wide skill provisioning | Team, Enterprise |
