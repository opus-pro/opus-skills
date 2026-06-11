---
name: opusclip
description: Turn long-form videos into short clips and post them to social platforms using the OpusClip API. Use when the user wants to clip a YouTube video, upload a local video for clipping, manage clip collections, list brand templates, share projects publicly, censor profanity, post clips to social media, schedule social posts, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "upload to opusclip", "post to youtube", "schedule post", "publish clip".
---

# OpusClip

Turn long-form videos into short clips via the OpusClip API.

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. If the user already has an Enterprise or Pro plan, they can copy their key from https://clip.opus.pro/dashboard. Otherwise, direct them to the [pricing page](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus) — API access requires Enterprise or Pro.
- The CLI at `scripts/opusclip` requires Node.js (>=18) — it is a bundled JS file

## CLI Quick Reference

Run the bundled CLI at `scripts/opusclip`. Commands follow a **resource + verb** tree (`opusclip <resource> <verb>`); all commands output JSON.

```
opusclip project create --url URL [options]   Submit video for clipping
opusclip project create --file PATH [options] Upload local video + create project
opusclip project list [--page N]              List the org's clip projects (most recent first)
opusclip project share --project ID           Share project publicly
opusclip project transcript --project ID      Get the source-video transcript (paragraphs + word timing in ms)
opusclip project preview --project ID [--output PATH]  Generate HTML preview and open in browser
opusclip clip list --project ID               List a project's clips
opusclip clip get --project ID --clip CID     Get clip details (transcript, layout info)
opusclip clip edit <verb> [flags]             Server-side clip edits (charged, re-renders the clip) (beta — pricing may change)
  get             Fetch EditingScript JSON for round-trip edits (beta — pricing may change)
  apply           Submit an edited EditingScript directly (beta — pricing may change)
  censor          Profanity censor (dictionary-based; --beep adds sound effect) (beta — pricing may change)
opusclip clip trim --project ID --clip CID --start S --end E   Local ffmpeg trim (no API call, no captions)
opusclip clip storyboard --project ID --clip CID   Generate 2x2 frame preview (requires ffmpeg)
opusclip collection <verb> [options]          Manage collections (list, clips, create, export, add-clip)
opusclip post <verb> [options]                Social posting (create, schedule, cancel)
  account list    List connected social accounts
  copy create     Generate AI-optimized post copy
  copy get        Poll for generated copy result
  schedule        Schedule a post for future publishing (beta — pricing may change)
opusclip thumbnail create --url URL [options] Generate YouTube thumbnails (experimental; credit-charged per call)
opusclip template list                        List brand templates
opusclip usage                                Show the org's API cap usage (monthly + concurrent, or uncapped)
```

Legacy bare-verb aliases (`submit`, `create-project`, `upload`, `list`, `get-clips`, `list-projects`, `describe`, `templates`, `transcript`, `share`, `share-project`, `collections`, `edit-clip`, `trim`, `storyboard`, `preview`, `post publish|accounts|generate-copy|copy-status`) still work, but the resource + verb forms below are canonical.

### project create

> **Copyright hint**
>
> Immediately before calling `opusclip project create`, narrate the following sentence to the user as a plain notice (not an `AskUserQuestion`, not a yes/no gate):
>
> > Using video you don't own may violate copyright laws. By continuing, you confirm this is your own original content.
>
> This mirrors the inline disclaimer the OpusClip web app shows on its submit panel. Show it verbatim on every `project create`; do not block on a confirmation.

```bash
opusclip project create --url "https://youtube.com/watch?v=..." --durations "30,60,90" [more options]
```

| Flag | Description |
|------|-------------|
| `--url` | (required unless `--file`) Video URL |
| `--file` | Upload a local video instead of a URL (handles the full 4-step GCS upload flow automatically; same remaining flags) |
| `--durations` | (required in practice) Target clip lengths in seconds, e.g. `"30,60,90"`. API rejects payloads without `curationPref.clipDurations`. |
| `--model` | `ClipBasic` (talking-head) or `ClipAnything` (diverse) |
| `--prompt` | Custom clipping prompt (ClipAnything only) |
| `--keywords` | Comma-separated topic keywords (ClipBasic only) |
| `--aspect` | `portrait` (default), `landscape`, `square` |
| `--range-start` / `--range-end` | Clip only a portion (seconds) |
| `--template` | Brand template ID |
| `--genre` | Video genre hint |
| `--lang` | Source language code |
| `--title` | Video title metadata |
| `--webhook` | Webhook URL for completion notification |
| `--skip-curate` | Process original video without AI curation |
| `--remove-filler` | Remove filler words |

### clip list

```bash
opusclip clip list --project PROJECT_ID
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID to fetch clips for |
| `--summary` | Deprecated no-op (kept for back-compat) — scored/human-readable fields are always included now |

To list the clips in a collection, use `collection clips --id COLLECTION_ID`.

Clips already include human-readable fields (title, description, hashtags, scores) by default. Display clips with their title and description rather than just clip IDs.

The output contains `project_id` and `clip_id` as separate fields. Use `clip_id` (e.g. `0RiWBs5xuF`) for `--clip` flags, not the composite ID.

### project list

List the calling org's clip projects, most recent first. Use this to find a `project_id` when the user hasn't given one.

```bash
opusclip project list
opusclip project list --page 1 --page-size 50
```

| Flag | Description |
|------|-------------|
| `--page` | Page number, 0-based (default 0) |
| `--page-size` | Items per page, 1–100 (default 20) |

Each row has `project_id`, `title`, `source_type`, `source_video_id`, `stage`, `created_at`, `updated_at`, `is_deleted`.

### project transcript

Get a project's source-video transcript: paragraphs with word-level timing (in milliseconds).

```bash
opusclip project transcript --project PROJECT_ID
```

| Flag | Description |
|------|-------------|
| `--project` | Project ID to fetch the transcript for |

Returns `{ project_id, paragraphs: [{ paragraph_id, start_ms, end_ms, text, words: [{ word, start_ms, end_ms }] }] }`. If the project has no transcript yet (still processing), `paragraphs` is omitted.

### project preview

Generate an HTML preview page with video players for all clips and open it in the browser.

```bash
opusclip project preview --project PROJECT_ID
opusclip project preview --project PROJECT_ID --output /path/to/output.html
```

| Flag | Description |
|------|-------------|
| `--project` | Project ID |
| `--output` | Custom output path (default: `/tmp/opusclip-preview-{id}.html`) |

The preview page shows clips sorted by score with inline video players, titles, descriptions, hashtags, and detailed AI scores (hook, coherence, connection, trend). Use this whenever the user wants to watch or preview their clips.

### project share

```bash
opusclip project share --project PROJECT_ID
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |

### collection

```bash
opusclip collection list
opusclip collection clips --id COL_ID
opusclip collection create --name "NAME"
opusclip collection export --id ID
opusclip collection add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
```

Destructive/complex collection operations (deleting a collection, removing a clip) are intentionally web-only — the CLI exposes only the basic, safe operations. Collections can be exported (download links) but cannot be shared publicly. To share clips publicly, use `project share --project` on the project instead.

### clip edit

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

> **Workflow guidance**
>
> Before running more than 3 `clip edit` operations on a single clip in one session, ask the user to confirm — these may incur charges that don't match the web UX.
>
> Never run `clip edit` or `post schedule` in a loop without user confirmation each iteration.

Server-side edits to an existing clip. All sub-verbs except `get` re-render the clip (charged, beta caps apply). The CLI does the EditingScript walking client-side; the API is a generic passthrough that mirrors the web editor's Save action. See `references/editing-script.md` for the mutation paths and recipes.

```bash
opusclip clip edit get             --project PID --clip CID [--output FILE]
opusclip clip edit apply           --project PID --clip CID --script FILE
opusclip clip edit censor          --project PID --clip CID [--beep]
```

> **caption edits / trims**
>
> The `caption-fix`, `caption-replace`, and server-side `trim` sub-verbs were removed (they hand-rolled EditingScripts in the CLI and drifted from the engine). For those edits use the `get` -> edit the EditingScript -> `apply` round-trip; see `references/editing-script.md` for worked recipes. `censor` is the one remaining convenience verb.

`apply` / `censor` return `{jobId}`. Poll status via `opusclip clip get --project PID --clip CID` — `render_pending` is `true` while the re-render runs (absent or false when done), and `export_url` then points at the new mp4.

For a caption typo or a trim, fetch the script with `clip edit get`, edit the relevant `textElement.text` or timing fields, then `clip edit apply --script FILE`. See `references/editing-script.md`. (`opusclip clip trim` remains as a free, instant, no-caption ffmpeg cut on the preview mp4.)

### clip get

Get structured information about a clip. Use this to understand clip content without watching the video.

```bash
opusclip clip get --project PROJECT_ID --clip CLIP_ID
opusclip clip get --transcript --project PROJECT_ID --clip CLIP_ID
opusclip clip get --layout --project PROJECT_ID --clip CLIP_ID
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--transcript` | Show only transcript text |
| `--layout` | Show only layout/framing info |

Without `--transcript` or `--layout`, the default output includes content fields (`title`, `description`, `transcript`, `hashtags`, `keywords`, `score`, `duration_sec`, `aspect`), media URLs (`preview_url`, `export_url`), and `render_pending` (`true` while a re-render is in flight; absent or false when done) — what powers re-render polling. Use `--transcript` when you only need the spoken text. Use `--layout` to check current framing before suggesting layout changes.

Polling a re-render (after any `clip edit` sub-verb):

```bash
while :; do
  opusclip clip get --project P --clip C \
    | jq -e '.render_pending != true' >/dev/null && break
  sleep 10
done
```

### clip storyboard

Generate a 2x2 frame grid image from a clip's preview video. Requires `ffmpeg`.

```bash
opusclip clip storyboard --project PROJECT_ID --clip CLIP_ID
opusclip clip storyboard --project PROJECT_ID --clip CLIP_ID --output /path/to/output.jpg
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--output` | Custom output path (default: `/tmp/opusclip-storyboard-{clipId}.jpg`) |

Opens the image automatically on macOS/Linux. Use this for quick visual review of a clip's content.

### clip trim

Trim a clip's preview video locally. Requires `ffmpeg`.

```bash
opusclip clip trim --project PROJECT_ID --clip CLIP_ID --start 3 --end 50
opusclip clip trim --project PROJECT_ID --clip CLIP_ID --start 3 --end 50 --output trimmed.mp4
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--start` | (required) Start time in seconds |
| `--end` | (required) End time in seconds |
| `--output` | Custom output path (default: `/tmp/opusclip-trimmed-{clipId}.mp4`) |

### post

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.** Applies to `post create` and `post schedule`.

> **Workflow guidance**
>
> Before scheduling more than 5 posts in one session, ask the user to confirm — scheduled posts may begin to incur per-post charges.
>
> Never run `clip edit` or `post schedule` in a loop without user confirmation each iteration.

Manage social posting — publish clips to YouTube, TikTok, Facebook, Instagram, LinkedIn, and X.

```bash
opusclip post account list
opusclip post copy create --project PID --clip CID --account AID [--prompt "tone"]
opusclip post copy get --job JOB_ID
opusclip post create --project PID --clip CID --account AID --title "Title" [--description "..."] [--privacy public]
opusclip post schedule --project PID --clip CID --account AID --title "Title" --at 2026-03-25T14:00:00Z
opusclip post cancel --schedule SCHEDULE_ID
```

| Subcommand | Description |
|------------|-------------|
| `account list` | List connected social accounts |
| `copy create` | Generate AI-optimized post copy for a clip |
| `copy get` | Poll for generated copy result |
| `create` | Publish a clip immediately |
| `schedule` | Schedule a clip for future publishing (beta — pricing may change) |
| `cancel` | Cancel a scheduled post |

Supported platforms: YouTube, TikTok Business, Facebook Page, Instagram Business, LinkedIn, X (Twitter). "Twitter" refers to X — the platform identifier is TWITTER. Each X post costs 1 credit.

When the user doesn't specify a post title, use the clip's title from the `clip list` output.

### thumbnail create

> **EXPERIMENTAL — features and pricing are subject to change. Daily caps apply. The endpoint may be temporarily disabled while in experimental status.**

Generate AI-designed YouTube thumbnails from a source video. Results are downloaded automatically on completion.

**Cost:** Every call is credit-charged for Pro/Enterprise callers — the API surface has no free quota (free quota is web-only). Each call costs a fixed number of credits (currently 7). Free/Starter callers get a `QuotaExceedErr`.

```bash
opusclip thumbnail create --url "https://youtube.com/watch?v=..."
opusclip thumbnail create --url URL --reference ./face.png --prompt "bold red text 'EPIC'" --output ./thumbs/
```

| Flag | Description |
|------|-------------|
| `--url` | (required) Source video URL — same sources as `project create` (`sourceUri`). |
| `--reference` | Optional local image to reference (face, brand asset). Uploaded via `/upload-links` `usecase: FreeToolMedia`. |
| `--mask` | Optional local image used as a mask. Same upload flow. |
| `--prompt` | Optional text prompt steering the design (style, copy). |
| `--output` | Output directory for downloaded PNGs (default: `/tmp/opusclip-thumbnails-{jobId}/`). |

The command POSTs to `/generative-jobs` with `jobType: thumbnail`, polls `GET /generative-jobs/{jobId}` every 5s, and downloads each `result.generatedThumbnailUris[]` into the output directory (opens it automatically on macOS).

Error codes:
- `403` — not on Pro/Enterprise, or the thumbnail jobType isn't exposed for your account.
- `429` — daily cap or 30 req/min rate limit hit (`Retry-After` may be present).
- `503` — the endpoint is temporarily disabled (kill switch). Try again later.

The endpoint is governed by a kill switch (`pro_api_generative_jobs_enabled`); a 503 means the capability is paused, not that something is wrong with your call.

### template list

```bash
opusclip template list
```

List brand templates. Use a template's ID with `project create --template`.

### usage

Show the calling org's API cap usage — answers "how much of my monthly API cap have I used / how close am I to the limit?". Takes no flags; reads `GET /api/api-usage?q=mine`.

```bash
opusclip usage
```

Two output shapes:

- **Capped:** `{ uncapped: false, monthly: { used, limit, remaining, reset_at }, concurrent: { used, limit } }`. The `monthly` numbers are the same ones stamped on every API response as `X-RateLimit-Limit` / `X-RateLimit-Remaining` (and `reset_at` is the ISO form of `X-RateLimit-Reset`), so this can't drift from what's actually enforced; `concurrent` is in-flight projects vs the concurrent cap.
- **Uncapped:** `{ uncapped: true }` — the workspace has no API cap (some Enterprise plans); no numbers to report.

## Common Workflows

### Clip a YouTube video
```bash
opusclip project create --url "https://youtube.com/watch?v=VIDEO_ID" --durations "30,60,90"
# Wait for processing, then:
opusclip clip list --project PROJECT_ID
# Preview clips in browser:
opusclip project preview --project PROJECT_ID
```

`--durations` is required in practice — the API rejects payloads without `curationPref.clipDurations`. Pick the target clip lengths you want generated (each value becomes a `[0, N]` bucket).

### Use ClipAnything with a custom prompt
```bash
opusclip project create \
  --url "https://youtube.com/watch?v=VIDEO_ID" \
  --model ClipAnything \
  --prompt "Find the most emotional moments" \
  --durations "30,60,90"
```

### Upload a local video, clip, and organize
```bash
opusclip project create --file video.mp4 --title "Interview" --model ClipBasic
opusclip clip list --project PROJECT_ID
opusclip collection create --name "Best Clips"
opusclip collection add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collection export --id COL_ID
```

### Clip, curate, and share
```bash
opusclip project create --url "https://youtube.com/watch?v=..." --durations "30,60,90"
opusclip clip list --project PROJECT_ID

# Understand clip content
opusclip clip get --transcript --project PROJECT_ID --clip CLIP_ID

# Visual review
opusclip clip storyboard --project PROJECT_ID --clip CLIP_ID

# Share
opusclip project share --project PROJECT_ID
```

### Clip, generate copy, and post to social

```bash
# 1. Submit and get clips
opusclip project create --url "https://youtube.com/watch?v=..." --durations "30,60,90"
opusclip clip list --project PROJECT_ID

# 2. See where you can post
opusclip post account list

# 3. Generate platform-optimized copy
opusclip post copy create --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --prompt "witty and engaging"
opusclip post copy get --job JOB_ID

# 4a. Publish immediately
opusclip post create --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "Check this out!"

# 4b. Or schedule for later
opusclip post schedule --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "Check this out!" --at 2026-03-25T14:00:00Z

# Cancel if needed
opusclip post cancel --schedule SCHEDULE_ID
```

### Edit a clip, then post

```bash
# Server-side edit (censor / apply)
opusclip clip edit censor --project PROJECT_ID --clip CLIP_ID --beep

# Wait for the re-render
while :; do
  opusclip clip get --project PROJECT_ID --clip CLIP_ID \
    | jq -e '.render_pending != true' >/dev/null && break
  sleep 10
done

# Post the edited clip
opusclip post create --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "..."
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video
- Thumbnail API: credit-charged per call (Pro/Enterprise only; currently 7 credits); experimental, may be disabled without notice (503)

## API Reference

For detailed endpoint schemas, parameters, and response formats, see [references/api-reference.md](references/api-reference.md).
