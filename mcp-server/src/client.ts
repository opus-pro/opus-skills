const DEFAULT_BASE_URL = "https://api.opus.pro/api";

export interface ClientOptions {
  apiKey: string;
  baseUrl?: string;
  extraHeaders?: Record<string, string>;
}

export class OpusClipClient {
  private readonly baseUrl: string;
  private readonly headers: Record<string, string>;

  constructor(opts: ClientOptions) {
    if (!opts.apiKey) {
      throw new Error(
        "OPUSCLIP_API_KEY is not set. API access requires an Enterprise plan: https://www.opus.pro/pricing"
      );
    }
    this.baseUrl = (opts.baseUrl ?? DEFAULT_BASE_URL).replace(/\/+$/, "");
    this.headers = {
      Authorization: `Bearer ${opts.apiKey}`,
      Accept: "application/json",
      ...opts.extraHeaders,
    };
  }

  async get(path: string, query?: Record<string, string | number | undefined>): Promise<unknown> {
    const url = new URL(this.baseUrl + path);
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        if (v !== undefined) url.searchParams.set(k, String(v));
      }
    }
    return this.request(url.toString(), { method: "GET" });
  }

  async post(path: string, body: unknown): Promise<unknown> {
    return this.request(this.baseUrl + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
    });
  }

  async delete(path: string): Promise<unknown> {
    return this.request(this.baseUrl + path, { method: "DELETE" });
  }

  private async request(url: string, init: RequestInit): Promise<unknown> {
    const res = await fetch(url, {
      ...init,
      headers: { ...this.headers, ...(init.headers ?? {}) },
    });
    const text = await res.text();
    if (!res.ok) {
      throw new Error(`OpusClip API ${res.status} ${res.statusText}: ${text.slice(0, 500)}`);
    }
    if (!text) return null;
    try {
      return JSON.parse(text);
    } catch {
      return text;
    }
  }
}

export function clientFromEnv(): OpusClipClient {
  const apiKey = process.env.OPUSCLIP_API_KEY ?? "";
  const baseUrl = process.env.OPUSCLIP_API_URL;
  const extraHeaders = parseExtraHeaders(process.env.OPUSCLIP_EXTRA_HEADERS);
  return new OpusClipClient({ apiKey, baseUrl, extraHeaders });
}

function parseExtraHeaders(raw: string | undefined): Record<string, string> | undefined {
  if (!raw) return undefined;
  const out: Record<string, string> = {};
  for (const part of raw.split(";")) {
    const idx = part.indexOf(":");
    if (idx < 0) continue;
    const k = part.slice(0, idx).trim();
    const v = part.slice(idx + 1).trim();
    if (k && v) out[k] = v;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

export function stripClipPrefix(clipId: string, projectId?: string): string {
  if (projectId && clipId.startsWith(projectId + ".")) {
    return clipId.slice(projectId.length + 1);
  }
  const dot = clipId.indexOf(".");
  return dot >= 0 ? clipId.slice(dot + 1) : clipId;
}
