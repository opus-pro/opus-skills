import { OpusClipClient, stripClipPrefix } from "./client.js";

export interface ToolDef {
  name: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, unknown>;
    required?: string[];
    additionalProperties?: boolean;
  };
  handler: (client: OpusClipClient, args: Record<string, unknown>) => Promise<unknown>;
}

const ASPECTS = ["portrait", "landscape", "square"] as const;
const MODELS = ["ClipBasic", "ClipAnything"] as const;

function str(args: Record<string, unknown>, key: string): string | undefined {
  const v = args[key];
  return typeof v === "string" && v.length > 0 ? v : undefined;
}
function strRequired(args: Record<string, unknown>, key: string): string {
  const v = str(args, key);
  if (!v) throw new Error(`${key} is required`);
  return v;
}
function num(args: Record<string, unknown>, key: string): number | undefined {
  const v = args[key];
  return typeof v === "number" && Number.isFinite(v) ? v : undefined;
}
function bool(args: Record<string, unknown>, key: string): boolean | undefined {
  const v = args[key];
  return typeof v === "boolean" ? v : undefined;
}
function arr(args: Record<string, unknown>, key: string): unknown[] | undefined {
  const v = args[key];
  return Array.isArray(v) ? v : undefined;
}

function buildSubmitPayload(args: Record<string, unknown>): Record<string, unknown> {
  const payload: Record<string, unknown> = { videoUrl: strRequired(args, "video_url") };

  const templateId = str(args, "brand_template_id");
  if (templateId) payload.brandTemplateId = templateId;

  const title = str(args, "title");
  if (title) payload.uploadedVideoAttr = { title };

  const curation: Record<string, unknown> = {};
  const model = str(args, "model");
  if (model) curation.model = model;
  const genre = str(args, "genre");
  if (genre) curation.genre = genre;
  const keywords = arr(args, "topic_keywords");
  if (keywords && keywords.length > 0) curation.topicKeywords = keywords;
  const customPrompt = str(args, "custom_prompt");
  if (customPrompt) curation.customPrompt = customPrompt;
  const durations = arr(args, "clip_durations");
  if (durations && durations.length > 0) {
    curation.clipDurations = (durations as number[]).map((d) => [0, d]);
  }
  const skipCurate = bool(args, "skip_curate");
  if (skipCurate) curation.skipCurate = true;
  const rangeStart = num(args, "range_start_sec");
  const rangeEnd = num(args, "range_end_sec");
  if (rangeStart !== undefined || rangeEnd !== undefined) {
    const range: Record<string, number> = {};
    if (rangeStart !== undefined) range.startSec = rangeStart;
    if (rangeEnd !== undefined) range.endSec = rangeEnd;
    curation.range = range;
  }
  if (Object.keys(curation).length > 0) payload.curationPref = curation;

  const aspect = str(args, "aspect") ?? "portrait";
  const render: Record<string, unknown> = { layoutAspectRatio: aspect };
  if (bool(args, "remove_filler_words")) {
    render.quickstartConfig = { enableRemoveFillerWords: true };
  }
  payload.renderPref = render;

  const sourceLang = str(args, "source_lang");
  if (sourceLang) payload.importPreference = { sourceLang };

  const webhookUrl = str(args, "webhook_url");
  if (webhookUrl) payload.conclusionActions = [{ type: "WEBHOOK", url: webhookUrl }];

  return payload;
}

const SUBMIT_PROPS = {
  video_url: { type: "string", description: "Public URL of the source video (YouTube, Vimeo, direct link, or upload_id from upload_local_video)." },
  brand_template_id: { type: "string", description: "Optional brand template ID. List available templates with list_brand_templates." },
  model: { type: "string", enum: MODELS, description: "Clipping model. ClipBasic for talking-head, ClipAnything for diverse footage." },
  genre: { type: "string", description: "Optional genre hint (Podcast, Tutorial, etc.)." },
  topic_keywords: { type: "array", items: { type: "string" }, description: "Topic keywords (ClipBasic only)." },
  custom_prompt: { type: "string", description: "Custom clipping prompt (ClipAnything only)." },
  aspect: { type: "string", enum: ASPECTS, description: "Output aspect ratio. Defaults to portrait." },
  clip_durations: { type: "array", items: { type: "number" }, description: "Target clip lengths in seconds, e.g. [30, 60]." },
  range_start_sec: { type: "number", description: "Clip only from this second onward." },
  range_end_sec: { type: "number", description: "Stop clipping at this second." },
  source_lang: { type: "string", description: "BCP-47 source language code (e.g. en, zh-CN)." },
  webhook_url: { type: "string", description: "Webhook URL called when clipping completes." },
  title: { type: "string", description: "Video title metadata." },
  skip_curate: { type: "boolean", description: "Process the original video without AI curation." },
  remove_filler_words: { type: "boolean", description: "Remove filler words from clips." },
};

export function buildTools(): ToolDef[] {
  return [
    {
      name: "submit_video",
      description:
        "Submit a video URL for AI clipping. Returns a clip-project. Poll list_clips with the returned project ID to see generated clips when ready.",
      inputSchema: {
        type: "object",
        properties: SUBMIT_PROPS,
        required: ["video_url"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.post("/clip-projects", buildSubmitPayload(args)),
    },

    {
      name: "list_clips",
      description:
        "List clips for a project OR a collection. Pass exactly one of project_id or collection_id. Set summary=true to include hook/coherence/connection/trend judge scores.",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string", description: "Project ID returned by submit_video." },
          collection_id: { type: "string", description: "Collection ID." },
          summary: { type: "boolean", description: "Include judge scores in the response." },
        },
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const projectId = str(args, "project_id");
        const collectionId = str(args, "collection_id");
        if (!projectId && !collectionId) throw new Error("project_id or collection_id is required");
        const query = projectId
          ? { q: "findByProjectId", projectId }
          : { q: "findByCollectionId", collectionId: collectionId! };
        const raw = (await c.get("/exportable-clips", query)) as { data?: unknown[] };
        const includeScores = bool(args, "summary") ?? false;
        return (raw.data ?? []).map((item) => projectClip(item, includeScores));
      },
    },

    {
      name: "describe_clip",
      description:
        "Get detailed information for a single clip — transcript, hashtags, layout, duration, and judge scores. Pass project_id and clip_id (composite ID from list_clips).",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          clip_id: { type: "string", description: "Clip ID (may be composite, e.g. P123.ClipABC)." },
          include_transcript: { type: "boolean", description: "Include transcript in the response (default true)." },
          include_layout: { type: "boolean", description: "Include layout info in the response (default true)." },
        },
        required: ["project_id", "clip_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const projectId = strRequired(args, "project_id");
        const clipId = strRequired(args, "clip_id");
        const wantTranscript = bool(args, "include_transcript") ?? true;
        const wantLayout = bool(args, "include_layout") ?? true;
        const data = (await c.get("/exportable-clips", { q: "findByProjectId", projectId })) as {
          data?: Array<Record<string, unknown>>;
        };
        const match = (data.data ?? []).find(
          (clip) => clip.id === clipId || clip.curationId === clipId
        );
        if (!match) return { error: `clip ${clipId} not found in project ${projectId}` };
        const out: Record<string, unknown> = {
          id: match.id,
          title: match.title,
          description: match.description,
          hashtags: match.hashtags,
          keywords: match.clipKeywords,
          duration_sec: Math.round(((match.durationMs as number) ?? 0) / 1000),
          score: match.score,
        };
        if (wantTranscript) out.transcript = match.text;
        if (wantLayout) {
          const render = match.renderPref as Record<string, unknown> | undefined;
          out.layout = render?.layoutType;
          out.aspect = render?.layoutAspectRatio;
        }
        return out;
      },
    },

    {
      name: "list_brand_templates",
      description: "List the user's brand templates. Use a template_id from this list with submit_video.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
      handler: async (c) => c.get("/brand-templates", { q: "mine" }),
    },

    {
      name: "share_project",
      description: "Update a project's visibility (PUBLIC or PRIVATE).",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          visibility: { type: "string", enum: ["PUBLIC", "PRIVATE"], description: "Defaults to PUBLIC." },
        },
        required: ["project_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const projectId = strRequired(args, "project_id");
        const visibility = str(args, "visibility") ?? "PUBLIC";
        return c.post(`/clip-projects/${projectId}/update-visibility`, { visibility });
      },
    },

    {
      name: "upload_local_video",
      description:
        "Upload a local video file (by absolute file_path) to OpusClip and create a clip project in one step. STDIO-only — the MCP server must have access to the file. Returns the clip-project.",
      inputSchema: {
        type: "object",
        properties: {
          file_path: { type: "string", description: "Absolute path to the local video file." },
          ...SUBMIT_PROPS,
        },
        required: ["file_path"],
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const filePath = strRequired(args, "file_path");
        const fs = await import("node:fs/promises");
        const buffer = await fs.readFile(filePath);
        const uploadResp = (await c.post("/upload-links", { video: { usecase: "LocalUpload" } })) as {
          url: string;
          uploadId: string;
        };
        const initRes = await fetch(uploadResp.url, {
          method: "POST",
          headers: { "x-goog-resumable": "start", "Content-Length": "0" },
        });
        const sessionUrl = initRes.headers.get("location");
        if (!sessionUrl) throw new Error("Resumable upload session URL not returned by GCS");
        const putRes = await fetch(sessionUrl, {
          method: "PUT",
          headers: { "Content-Type": "application/octet-stream" },
          body: buffer,
        });
        if (!putRes.ok) {
          throw new Error(`GCS upload failed: ${putRes.status} ${putRes.statusText}`);
        }
        return c.post("/clip-projects", buildSubmitPayload({ ...args, video_url: uploadResp.uploadId }));
      },
    },

    {
      name: "list_collections",
      description: "List collections. By default returns the user's collections; pass content_id to find collections containing a specific clip.",
      inputSchema: {
        type: "object",
        properties: {
          content_id: { type: "string", description: "Optional composite clip ID to filter collections by." },
        },
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const contentId = str(args, "content_id");
        return contentId
          ? c.get("/collections", { q: "findByContentId", contentId })
          : c.get("/collections", { q: "mine" });
      },
    },

    {
      name: "create_collection",
      description: "Create a new collection by name.",
      inputSchema: {
        type: "object",
        properties: { name: { type: "string" } },
        required: ["name"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.post("/collections", { collectionName: strRequired(args, "name") }),
    },

    {
      name: "delete_collection",
      description: "Permanently delete a collection.",
      inputSchema: {
        type: "object",
        properties: { collection_id: { type: "string" } },
        required: ["collection_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.delete(`/collections/${strRequired(args, "collection_id")}`),
    },

    {
      name: "export_collection",
      description: "Export a collection (assembles all clips into a single downloadable artifact).",
      inputSchema: {
        type: "object",
        properties: { collection_id: { type: "string" } },
        required: ["collection_id"],
        additionalProperties: false,
      },
      handler: async (c, args) =>
        c.post(`/collections/${strRequired(args, "collection_id")}/export`, {}),
    },

    {
      name: "add_clip_to_collection",
      description: "Add a clip to a collection. content_id is the composite clip ID (project_id.clip_id).",
      inputSchema: {
        type: "object",
        properties: {
          collection_id: { type: "string" },
          content_id: { type: "string", description: "Composite clip ID, e.g. P123.ClipABC." },
        },
        required: ["collection_id", "content_id"],
        additionalProperties: false,
      },
      handler: async (c, args) =>
        c.post("/collection-contents", {
          collectionId: strRequired(args, "collection_id"),
          contentId: strRequired(args, "content_id"),
        }),
    },

    {
      name: "remove_clip_from_collection",
      description: "Remove a clip from a collection.",
      inputSchema: {
        type: "object",
        properties: {
          collection_id: { type: "string" },
          content_id: { type: "string" },
        },
        required: ["collection_id", "content_id"],
        additionalProperties: false,
      },
      handler: async (c, args) =>
        c.post("/collection-contents/delete-collection-contents", {
          q: "findByCollectionIdAndContentId",
          collectionId: strRequired(args, "collection_id"),
          contentId: strRequired(args, "content_id"),
        }),
    },

    {
      name: "create_censor_job",
      description: "Start a profanity-censor job on a clip. Optionally replace with a beep.",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          clip_id: { type: "string", description: "Clip ID; composite IDs are stripped automatically." },
          beep: { type: "boolean", description: "Replace profanity with beep sound (default false: mute)." },
        },
        required: ["project_id", "clip_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const projectId = strRequired(args, "project_id");
        const clipId = stripClipPrefix(strRequired(args, "clip_id"), projectId);
        return c.post("/censor-jobs", {
          projectId,
          clipId,
          options: { beepSound: bool(args, "beep") ?? false },
        });
      },
    },

    {
      name: "get_censor_status",
      description: "Get the status of a censor job.",
      inputSchema: {
        type: "object",
        properties: { job_id: { type: "string" } },
        required: ["job_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.get(`/censor-jobs/${strRequired(args, "job_id")}`),
    },

    {
      name: "list_social_accounts",
      description: "List the user's connected social posting accounts (YouTube, TikTok, Instagram, Facebook, LinkedIn, X).",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
      handler: async (c) => {
        const raw = (await c.get("/social-accounts", { q: "mine" })) as { data?: Array<Record<string, unknown>> };
        return (raw.data ?? []).map((a) => ({
          post_account_id: a.postAccountId,
          sub_account_id: a.subAccountId,
          platform: a.platform,
          name: a.extUserName,
          profile_url: a.extUserProfileLink,
        }));
      },
    },

    {
      name: "generate_social_copy",
      description: "Generate platform-tailored copy (caption/title) for a clip on a specific social account. Returns a job ID; poll get_social_copy_status.",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          clip_id: { type: "string" },
          post_account_id: { type: "string" },
          sub_account_id: { type: "string", description: "Optional channel sub-account (e.g. specific YouTube channel under a Google account)." },
          prompt: { type: "string", description: "Tone or angle hint (e.g. 'witty', 'professional')." },
          force_regenerate: { type: "boolean" },
        },
        required: ["project_id", "clip_id", "post_account_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => {
        const projectId = strRequired(args, "project_id");
        const payload: Record<string, unknown> = {
          projectId,
          clipId: stripClipPrefix(strRequired(args, "clip_id"), projectId),
          postAccountId: strRequired(args, "post_account_id"),
        };
        const subAccount = str(args, "sub_account_id");
        if (subAccount) payload.subAccountId = subAccount;
        const prompt = str(args, "prompt");
        if (prompt) payload.prompt = prompt;
        if (bool(args, "force_regenerate")) payload.forceRegenerate = true;
        return c.post("/social-copy-jobs", payload);
      },
    },

    {
      name: "get_social_copy_status",
      description: "Get the status (and generated copy, when ready) of a social-copy job.",
      inputSchema: {
        type: "object",
        properties: { job_id: { type: "string" } },
        required: ["job_id"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.get(`/social-copy-jobs/${strRequired(args, "job_id")}`),
    },

    {
      name: "publish_clip",
      description: "Publish a clip immediately to a connected social account.",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          clip_id: { type: "string" },
          post_account_id: { type: "string" },
          sub_account_id: { type: "string" },
          title: { type: "string" },
          description: { type: "string" },
          privacy: { type: "string", description: "Platform-specific privacy (e.g. PUBLIC, PRIVATE, UNLISTED for YouTube)." },
          media_type: { type: "string", description: "Optional media-type override (e.g. SHORT, REEL)." },
        },
        required: ["project_id", "clip_id", "post_account_id", "title"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.post("/post-tasks", buildPostPayload(args, false)),
    },

    {
      name: "schedule_post",
      description: "Schedule a clip to publish at a future time (ISO 8601 UTC).",
      inputSchema: {
        type: "object",
        properties: {
          project_id: { type: "string" },
          clip_id: { type: "string" },
          post_account_id: { type: "string" },
          sub_account_id: { type: "string" },
          title: { type: "string" },
          description: { type: "string" },
          privacy: { type: "string" },
          media_type: { type: "string" },
          publish_at: { type: "string", description: "ISO 8601 UTC timestamp, e.g. 2026-03-25T14:00:00Z." },
        },
        required: ["project_id", "clip_id", "post_account_id", "title", "publish_at"],
        additionalProperties: false,
      },
      handler: async (c, args) => c.post("/publish-schedules", buildPostPayload(args, true)),
    },

    {
      name: "cancel_scheduled_post",
      description: "Cancel a scheduled post by its schedule ID.",
      inputSchema: {
        type: "object",
        properties: { schedule_id: { type: "string" } },
        required: ["schedule_id"],
        additionalProperties: false,
      },
      handler: async (c, args) =>
        c.delete(`/publish-schedules/${strRequired(args, "schedule_id")}`),
    },
  ];
}

function projectClip(item: unknown, includeScores: boolean): Record<string, unknown> {
  const c = item as Record<string, unknown>;
  const id = c.id as string;
  const parts = id?.split(".") ?? [];
  const out: Record<string, unknown> = {
    project_id: parts[0],
    clip_id: parts.slice(1).join("."),
    rank: c.rank,
    score: c.score,
    title: c.title,
    description: c.description,
    hashtags: c.hashtags,
    duration_sec: Math.round(((c.durationMs as number) ?? 0) / 1000),
    is_bonus: c.isBonusClip,
    preview_url: c.uriForPreview,
    export_url: c.uriForExport,
    thumbnail_url: c.uriForThumbnail,
  };
  if (includeScores) {
    const judge = (c.judgeResult ?? {}) as Record<string, unknown>;
    out.hook_score = judge.hookScore;
    out.coherence_score = judge.coherenceScore;
    out.connection_score = judge.connectionScore;
    out.trend_score = judge.trendScore;
  }
  return out;
}

function buildPostPayload(args: Record<string, unknown>, scheduled: boolean): Record<string, unknown> {
  const projectId = strRequired(args, "project_id");
  const clipId = stripClipPrefix(strRequired(args, "clip_id"), projectId);
  const postAccountId = strRequired(args, "post_account_id");
  const title = strRequired(args, "title");

  const postDetail: Record<string, unknown> = { title };
  const mediaType = str(args, "media_type");
  if (mediaType) postDetail.mediaType = mediaType;
  const custom: Record<string, unknown> = {};
  const description = str(args, "description");
  if (description) custom.description = description;
  const privacy = str(args, "privacy");
  if (privacy) custom.privacy = privacy;
  if (Object.keys(custom).length > 0) postDetail.custom = custom;

  const payload: Record<string, unknown> = {
    projectId,
    clipId,
    postAccountId,
    postDetail,
  };
  const subAccount = str(args, "sub_account_id");
  if (subAccount) payload.subAccountId = subAccount;
  if (scheduled) payload.publishAt = strRequired(args, "publish_at");
  return payload;
}
