#!/usr/bin/env node
import { createServer as createHttpServer } from "node:http";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { OpusClipClient } from "./client.js";
import { createServer } from "./server.js";

const PORT = Number(process.env.PORT ?? 3000);
const PATH = process.env.MCP_PATH ?? "/mcp";

async function main() {
  const baseUrl = process.env.OPUSCLIP_API_URL;

  const http = createHttpServer(async (req, res) => {
    if (!req.url?.startsWith(PATH)) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not found");
      return;
    }

    const apiKey = extractBearer(req.headers.authorization);
    if (!apiKey) {
      res.writeHead(401, { "Content-Type": "text/plain" });
      res.end("Missing Authorization: Bearer <OPUSCLIP_API_KEY>");
      return;
    }

    const client = new OpusClipClient({ apiKey, baseUrl });
    const server = createServer(client);
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: () => crypto.randomUUID() });
    await server.connect(transport);
    await transport.handleRequest(req, res);
  });

  http.listen(PORT, () => {
    console.error(`opusclip-mcp listening on http://0.0.0.0:${PORT}${PATH}`);
  });
}

function extractBearer(header: string | undefined): string | null {
  if (!header) return null;
  const m = header.match(/^Bearer\s+(\S+)$/i);
  return m ? m[1] : null;
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
