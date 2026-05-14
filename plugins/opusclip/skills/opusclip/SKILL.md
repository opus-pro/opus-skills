---
name: opusclip
description: Turn long-form videos into short clips and post them to social platforms using the OpusClip API. Use when the user wants to clip a YouTube video, upload a local video for clipping, manage clip collections, list brand templates, share projects publicly, censor profanity, post clips to social media, schedule social posts, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "upload to opusclip", "post to youtube", "schedule post", "publish clip".
---

# OpusClip

Turn long-form videos into short clips via the OpusClip API.

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. Copy from https://clip.opus.pro/dashboard with an [Enterprise plan](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus).
- For MCP tools: nothing else — Claude Code spawns `node mcp-server.mjs` (the bundled JS shipped with this plugin).
- For bash CLI fallback: `curl` and `jq` on PATH (`ffmpeg` for storyboard / trim).

## Tool dispatch: MCP first, bash CLI fallback

Two ways to call the OpusClip API ship with this plugin:

1. **MCP tools** (preferred) — tools are named `mcp__plugin_opusclip_opusclip__<tool>` (Claude Code) or appear under the `opusclip` server in the host's tool palette (Codex, OpenClaw, Claude.ai). If MCP tools are listed in the available tools, call them directly.
2. **Bash CLI** (fallback) — `scripts/opusclip <command>` in this skill directory. Use when no MCP tools are listed, or for ffmpeg-based local utilities (storyboard, trim).

## MCP tools (20)

All take JSON arguments and return JSON.

| Tool | Purpose | Bash CLI equivalent |
|---|---|---|
| `submit_video` | Submit a video URL for clipping | `opusclip submit --url ...` |
| `list_clips` | List clips in a project or collection | `opusclip list --project ID` |
| `describe_clip` | Get one clip's transcript / layout / scores | `opusclip describe ...` |
| `list_brand_templates` | List the user's brand templates | `opusclip templates` |
| `share_project` | Set project visibility (PUBLIC / PRIVATE) | `opusclip share --project ID` |
| `upload_local_video` | Upload a local file then create a project (stdio-only) | `opusclip upload --file ...` |
| `list_collections` | List collections (optionally by `content_id`) | `opusclip collections list` |
| `create_collection` | Make a new collection | `opusclip collections create` |
| `delete_collection` | Delete a collection | `opusclip collections delete` |
| `export_collection` | Compile a collection into one artifact | `opusclip collections export` |
| `add_clip_to_collection` | Add a clip to a collection | `opusclip collections add-clip` |
| `remove_clip_from_collection` | Remove a clip from a collection | `opusclip collections remove-clip` |
| `create_censor_job` | Start a profanity censor job | `opusclip censor create` |
| `get_censor_status` | Check censor-job status | `opusclip censor status` |
| `list_social_accounts` | List connected social posting accounts | `opusclip post accounts` |
| `generate_social_copy` | Generate platform-tailored caption/title | `opusclip post generate-copy` |
| `get_social_copy_status` | Poll generated copy | `opusclip post copy-status` |
| `publish_clip` | Publish a clip immediately | `opusclip post publish` |
| `schedule_post` | Schedule a clip for future publish | `opusclip post schedule` |
| `cancel_scheduled_post` | Cancel a scheduled post | `opusclip post cancel` |

### Tool argument shapes

`submit_video` — required: `video_url`. Optional: `brand_template_id`, `model` (`ClipBasic` | `ClipAnything`), `genre`, `topic_keywords` (array, ClipBasic), `custom_prompt` (ClipAnything), `aspect` (`portrait` | `landscape` | `square`, default portrait), `clip_durations` (array of seconds, e.g. `[30, 60]`), `range_start_sec`, `range_end_sec`, `source_lang`, `webhook_url`, `title`, `skip_curate`, `remove_filler_words`.

`list_clips` — pass exactly one of `project_id` or `collection_id`. `summary: true` adds hook/coherence/connection/trend judge scores.

`describe_clip` — required: `project_id`, `clip_id`. Defaults include transcript and layout; toggle with `include_transcript`, `include_layout`.

Posting tools — `clip_id` may be the composite ID (`P123.ClipABC`); the server strips the prefix automatically.

Local-only constraint — `upload_local_video` reads from the host filesystem, so it only works in stdio mode (Claude Code, Codex CLI/App, OpenClaw). Hosted Claude.ai / Cowork can't access local files; fall back to a public URL with `submit_video`.

## Bash CLI fallback

Run `scripts/opusclip` from this skill directory. Output is JSON.

```
opusclip submit --url URL [options]           Submit video for clipping (alias: create-project)
opusclip list --project ID [--summary]        List clips (alias: get-clips)
opusclip describe --project ID --clip CID     Get clip details (transcript, layout info)
opusclip storyboard --project ID --clip CID   Generate 2x2 frame preview (requires ffmpeg)
opusclip trim --project ID --clip CID --start S --end E  Local trim (requires ffmpeg)
opusclip share --project ID                   Share project (alias: share-project)
opusclip templates                            List brand templates
opusclip upload --file PATH [options]         Upload local video + create project
opusclip collections <sub> [options]          Manage collections
opusclip censor <sub> [options]               Censor profanity in clips
opusclip post <sub> [options]                 Social posting (publish, schedule, generate copy)
```

`submit` flags: `--url` (required), `--model {ClipBasic|ClipAnything}`, `--prompt` (ClipAnything), `--keywords "a,b,c"` (ClipBasic), `--aspect {portrait|landscape|square}`, `--durations "30,60"`, `--range-start S --range-end S`, `--template ID`, `--genre`, `--lang`, `--title`, `--webhook URL`, `--skip-curate`, `--remove-filler`.

`list` flags: `--project ID` or `--collection ID`, `--summary` for judge scores. When presenting clips to the user, use `--summary` to get title/description/hashtags/scores.

`describe` flags: `--project ID --clip CID`, optional `--transcript` or `--layout` to limit output. Without those flags, returns both.

`storyboard` / `trim` flags: `--project --clip` + (for trim) `--start --end --output`. Both require ffmpeg.

`share` flags: `--project ID` (visibility defaults to PUBLIC; pass `--visibility PRIVATE` to revert).

`collections` subcommands: `list`, `create --name NAME`, `delete --id ID`, `export --id ID`, `add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID`, `remove-clip` (same args).

`censor` subcommands: `create --project --clip [--beep]`, `status --job JOB_ID`. Statuses: `QUEUED` → `PROCESSING` → `CONCLUDED` / `FAILED`.

`post` subcommands: `accounts`, `generate-copy`, `copy-status --job ID`, `publish`, `schedule --at ISO_8601_UTC`, `cancel --schedule ID`. Supported platforms: YouTube, TikTok Business, Facebook Page, Instagram Business, LinkedIn, X (platform identifier `TWITTER`; each X post costs 1 credit).

When the user doesn't specify a post title, use the clip's title from `list --summary`.

## Common workflows

### Clip a YouTube video
```
submit_video(video_url="https://youtube.com/watch?v=...")
list_clips(project_id="<from submit>", summary=true)
```
Bash equivalent: `opusclip submit --url ...; opusclip list --project ID --summary`

### Use ClipAnything with a custom prompt
```
submit_video(
  video_url="https://youtube.com/watch?v=...",
  model="ClipAnything",
  custom_prompt="Find the most emotional moments",
  clip_durations=[30, 60, 90]
)
```

### Upload a local file, clip, and organize into a collection
```
upload_local_video(file_path="/abs/path/video.mp4", title="Interview", model="ClipBasic")
list_clips(project_id="<from upload>")
create_collection(name="Best Clips")
add_clip_to_collection(collection_id="<from create>", content_id="<project_id>.<clip_id>")
export_collection(collection_id="<from create>")
```

### Clip, generate copy, post to social
```
submit_video(video_url="...")
list_clips(project_id="...", summary=true)
list_social_accounts()
generate_social_copy(project_id="...", clip_id="...", post_account_id="...", prompt="witty")
get_social_copy_status(job_id="...")
publish_clip(project_id="...", clip_id="...", post_account_id="...", title="...")
# or schedule:
schedule_post(... , publish_at="2026-03-25T14:00:00Z")
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video

## API reference

For detailed endpoint schemas, request/response shapes, and edge cases, see [references/api-reference.md](references/api-reference.md).
