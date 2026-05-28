---
name: opusclip
description: Turn long-form videos into short clips and post them to social platforms using the OpusClip API. Use when the user wants to clip a YouTube video, upload a local video for clipping, manage clip collections, list brand templates, share projects publicly, censor profanity, post clips to social media, schedule social posts, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "upload to opusclip", "post to youtube", "schedule post", "publish clip".
---

# OpusClip

Turn long-form videos into short clips via the OpusClip API.

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. If the user already has an Enterprise or Pro plan, they can copy their key from https://clip.opus.pro/dashboard. Otherwise, direct them to the [pricing page](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus) — API access requires Enterprise or Pro.
- The CLI at `scripts/opusclip` requires `curl` and `jq`

## CLI Quick Reference

Run the bundled CLI at `scripts/opusclip`. All commands output JSON.

```
opusclip submit --url URL [options]           Submit video for clipping (alias: create-project)
opusclip list --project ID [--summary]        List clips (alias: get-clips)
opusclip describe --project ID --clip CID     Get clip details (transcript, layout info)
opusclip storyboard --project ID --clip CID   Generate 2x2 frame preview (requires ffmpeg)
opusclip trim --project ID --clip CID --start S --end E    Local ffmpeg trim (no API call, no captions)
opusclip edit-clip <sub> [flags]              Server-side clip edits (charged, re-renders the clip) (beta — pricing may change)
  get             Fetch EditingScript JSON for round-trip edits (beta — pricing may change)
  apply           Submit an edited EditingScript directly (beta — pricing may change)
  caption-fix     Replace caption text (--find X --replace Y) (beta — pricing may change)
  caption-replace Replace caption track from a transcript file (--transcript FILE) (beta — pricing may change)
  censor          Profanity censor (dictionary-based; --beep adds sound effect) (beta — pricing may change)
  trim            Server-side trim (--start S --end E; shrink only) (beta — pricing may change)
opusclip preview --project ID [--output PATH] Generate HTML preview and open in browser
opusclip share --project ID                   Share project (alias: share-project)
opusclip templates                            List brand templates
opusclip upload --file PATH [options]         Upload local video + create project
opusclip thumbnail --url URL [options]        Generate YouTube thumbnails (experimental; credit-charged per call)
opusclip collections <sub> [options]          Manage collections
opusclip post <sub> [options]                 Social posting (publish, schedule, generate copy)
  schedule        Schedule a post for future publishing (beta — pricing may change)
```

### submit

Alias: `create-project`

> **Copyright hint**
>
> Immediately before calling `opusclip submit` or `opusclip upload`, narrate the following sentence to the user as a plain notice (not an `AskUserQuestion`, not a yes/no gate):
>
> > Using video you don't own may violate copyright laws. By continuing, you confirm this is your own original content.
>
> This mirrors the inline disclaimer the OpusClip web app shows on its submit panel. Show it verbatim on every submit/upload; do not block on a confirmation.

```bash
opusclip submit --url "https://youtube.com/watch?v=..." --durations "30,60,90" [more options]
```

| Flag | Description |
|------|-------------|
| `--url` | (required) Video URL |
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

### upload

Same flags as `submit` plus `--file PATH`. Handles the full 4-step GCS upload flow automatically.

### list

Alias: `get-clips`

```bash
opusclip list --project PROJECT_ID
opusclip list --project PROJECT_ID --summary
opusclip list --collection COLLECTION_ID
```

| Flag | Description |
|------|-------------|
| `--project` | Project ID to fetch clips for |
| `--collection` | Collection ID to fetch clips for |
| `--summary` | Output condensed JSON with title, description, hashtags, scores, duration, and preview/export URLs (instead of full raw response) |

When presenting clips to the user, always use `--summary` to get human-readable fields (title, description, hashtags, scores). Display clips with their title and description rather than just clip IDs.

The output contains `project_id` and `clip_id` as separate fields. Use `clip_id` (e.g. `0RiWBs5xuF`) for `--clip` flags, not the composite ID.

### preview

Generate an HTML preview page with video players for all clips and open it in the browser.

```bash
opusclip preview --project PROJECT_ID
opusclip preview --project PROJECT_ID --output /path/to/output.html
opusclip preview --collection COLLECTION_ID
```

| Flag | Description |
|------|-------------|
| `--project` | Project ID |
| `--collection` | Collection ID |
| `--output` | Custom output path (default: `/tmp/opusclip-preview-{id}.html`) |

The preview page shows clips sorted by score with inline video players, titles, descriptions, hashtags, and detailed AI scores (hook, coherence, connection, trend). Use this whenever the user wants to watch or preview their clips.

### share

Alias: `share-project`

```bash
opusclip share --project PROJECT_ID
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |

### collections

```bash
opusclip collections list
opusclip collections create --name "NAME"
opusclip collections delete --id ID
opusclip collections export --id ID
opusclip collections add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collections remove-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
```

Collections can be exported (download links) but cannot be shared publicly. To share clips publicly, use `share --project` on the project instead.

### edit-clip

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.**

> **Workflow guidance**
>
> Before running more than 3 edit-clip operations on a single clip in one session, ask the user to confirm — these may incur charges that don't match the web UX.
>
> Never run edit-clip or post schedule in a loop without user confirmation each iteration.

Server-side edits to an existing clip. All sub-verbs except `get` re-render the clip (charged, beta caps apply). The CLI does the EditingScript walking client-side; the API is a generic passthrough that mirrors the web editor's Save action. See `references/editing-script.md` for the mutation paths and recipes.

```bash
opusclip edit-clip get             --project PID --clip CID [--output FILE]
opusclip edit-clip apply           --project PID --clip CID --script FILE
opusclip edit-clip caption-fix     --project PID --clip CID --find X --replace Y [--ignore-case]
opusclip edit-clip caption-replace --project PID --clip CID --transcript FILE
opusclip edit-clip censor          --project PID --clip CID [--beep]
opusclip edit-clip trim            --project PID --clip CID --start S --end E
```

> **`edit-clip apply` guidance**
>
> `edit-clip apply` is an escape hatch. Prefer named sub-verbs (`caption-fix`, `caption-replace`, `censor`, `trim`) where they cover the user's intent. Only reach for `apply` when no sub-verb fits.

All sub-verbs return `{jobId}` (or `{message, matchCount: 0}` when nothing matched). Poll status via `opusclip describe --project PID --clip CID` — `renderAsVideoFile.pending` flips false when the new render is ready and `uriForExport` then points at the new mp4.

`caption-fix` notes:
- **Single-word `--find`** is a regex `gsub` over every caption textElement's `.text` (so it matches inside words too: `--find "haha" --replace "ha"`).
- **Multi-word `--find`** walks consecutive textElements and replaces them 1:1 — `--replace` must have the same word count (`"2 lonely"` → `"Two lonely"` works, `"2"` → `"Two and"` does not). For different-length rewrites use `caption-replace` (whole transcript) or `apply` (custom EditingScript).

`edit-clip trim` is the server-side, captioned, brand-styled version. The top-level `opusclip trim` is the local-ffmpeg fast path on the preview mp4 (free, instant, no captions). Use whichever fits the situation. `edit-clip trim` clamps `--end` to the clip's current `durationMs` (the engine no-ops on extends); the response includes `clampedEndMs` and a `note` when the clamp triggers.

### describe

Get structured information about a clip. Use this to understand clip content without watching the video.

```bash
opusclip describe --project PROJECT_ID --clip CLIP_ID
opusclip describe --transcript --project PROJECT_ID --clip CLIP_ID
opusclip describe --layout --project PROJECT_ID --clip CLIP_ID
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--transcript` | Show only transcript text |
| `--layout` | Show only layout/framing info |

Without `--transcript` or `--layout`, the default output includes content fields (`title`, `description`, `transcript`, `hashtags`, `keywords`, `score`, `duration_sec`/`durationMs`) **and** render-state fields (`uriForPreview`, `uriForExport`, `renderAsVideoPreview`, `renderAsVideoFile`) — the latter is what powers re-render polling. Use `--transcript` when you only need the spoken text. Use `--layout` to check current framing before suggesting layout changes.

Polling a re-render (after any `edit-clip` sub-verb):

```bash
while :; do
  opusclip describe --project P --clip C \
    | jq -e '.renderAsVideoFile.pending == false' >/dev/null && break
  sleep 10
done
```

### storyboard

Generate a 2x2 frame grid image from a clip's preview video. Requires `ffmpeg`.

```bash
opusclip storyboard --project PROJECT_ID --clip CLIP_ID
opusclip storyboard --project PROJECT_ID --clip CLIP_ID --output /path/to/output.jpg
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--output` | Custom output path (default: `/tmp/opusclip-storyboard-{clipId}.jpg`) |

Opens the image automatically on macOS/Linux. Use this for quick visual review of a clip's content.

### trim

Trim a clip's preview video locally. Requires `ffmpeg`.

```bash
opusclip trim --project PROJECT_ID --clip CLIP_ID --start 3 --end 50
opusclip trim --project PROJECT_ID --clip CLIP_ID --start 3 --end 50 --output trimmed.mp4
```

| Flag | Description |
|------|-------------|
| `--project` | (required) Project ID |
| `--clip` | (required) Clip ID |
| `--start` | (required) Start time in seconds |
| `--end` | (required) End time in seconds |
| `--output` | Custom output path (default: `/tmp/opusclip-trimmed-{clipId}.mp4`) |

### post

> **BETA — features and pricing are subject to change. API pricing may diverge from web pricing.** Applies to `post publish` and `post schedule`.

> **Workflow guidance**
>
> Before scheduling more than 5 posts in one session, ask the user to confirm — scheduled posts may begin to incur per-post charges.
>
> Never run edit-clip or post schedule in a loop without user confirmation each iteration.

Manage social posting — publish clips to YouTube, TikTok, Facebook, Instagram, LinkedIn, and X.

```bash
opusclip post accounts
opusclip post generate-copy --project PID --clip CID --account AID [--prompt "tone"]
opusclip post copy-status --job JOB_ID
opusclip post publish --project PID --clip CID --account AID --title "Title" [--description "..."] [--privacy public]
opusclip post schedule --project PID --clip CID --account AID --title "Title" --at 2026-03-25T14:00:00Z
opusclip post cancel --schedule SCHEDULE_ID
```

| Subcommand | Description |
|------------|-------------|
| `accounts` | List connected social accounts (default) |
| `generate-copy` | Generate AI-optimized post copy for a clip |
| `copy-status` | Poll for generated copy result |
| `publish` | Publish a clip immediately |
| `schedule` | Schedule a clip for future publishing (beta — pricing may change) |
| `cancel` | Cancel a scheduled post |

Supported platforms: YouTube, TikTok Business, Facebook Page, Instagram Business, LinkedIn, X (Twitter). "Twitter" refers to X — the platform identifier is TWITTER. Each X post costs 1 credit.

When the user doesn't specify a post title, use the clip's title from the `list --summary` output.

### thumbnail

> **EXPERIMENTAL — features and pricing are subject to change. Daily caps apply. The endpoint may be temporarily disabled while in experimental status.**

Generate AI-designed YouTube thumbnails from a source video. Results are downloaded automatically on completion.

**Cost:** Every call is credit-charged for Pro/Enterprise callers — the API surface has no free quota (free quota is web-only). The per-call credit amount comes from Statsig `growth-tool-quota-config.thumbnail.credit.amount` (code default fallback: 5). Free/Starter callers get a `QuotaExceedErr`. Verify the live Statsig value if you need to quote an exact number.

```bash
opusclip thumbnail --url "https://youtube.com/watch?v=..."
opusclip thumbnail --url URL --reference ./face.png --prompt "bold red text 'EPIC'" --output ./thumbs/
```

| Flag | Description |
|------|-------------|
| `--url` | (required) Source video URL — same sources as `submit` (`sourceUri`). |
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

## Common Workflows

### Clip a YouTube video
```bash
opusclip submit --url "https://youtube.com/watch?v=VIDEO_ID" --durations "30,60,90"
# Wait for processing, then:
opusclip list --project PROJECT_ID --summary
# Preview clips in browser:
opusclip preview --project PROJECT_ID
```

`--durations` is required in practice — the API rejects payloads without `curationPref.clipDurations`. Pick the target clip lengths you want generated (each value becomes a `[0, N]` bucket).

### Use ClipAnything with a custom prompt
```bash
opusclip submit \
  --url "https://youtube.com/watch?v=VIDEO_ID" \
  --model ClipAnything \
  --prompt "Find the most emotional moments" \
  --durations "30,60,90"
```

### Upload a local video, clip, and organize
```bash
opusclip upload --file video.mp4 --title "Interview" --model ClipBasic
opusclip list --project PROJECT_ID
opusclip collections create --name "Best Clips"
opusclip collections add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collections export --id COL_ID
```

### Clip, curate, and share
```bash
opusclip submit --url "https://youtube.com/watch?v=..." --durations "30,60,90"
opusclip list --project PROJECT_ID --summary

# Understand clip content
opusclip describe --transcript --project PROJECT_ID --clip CLIP_ID

# Visual review
opusclip storyboard --project PROJECT_ID --clip CLIP_ID

# Share
opusclip share --project PROJECT_ID
```

### Clip, generate copy, and post to social

```bash
# 1. Submit and get clips
opusclip submit --url "https://youtube.com/watch?v=..." --durations "30,60,90"
opusclip list --project PROJECT_ID --summary

# 2. See where you can post
opusclip post accounts

# 3. Generate platform-optimized copy
opusclip post generate-copy --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --prompt "witty and engaging"
opusclip post copy-status --job JOB_ID

# 4a. Publish immediately
opusclip post publish --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "Check this out!"

# 4b. Or schedule for later
opusclip post schedule --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "Check this out!" --at 2026-03-25T14:00:00Z

# Cancel if needed
opusclip post cancel --schedule SCHEDULE_ID
```

### Edit a clip, then post

```bash
# Server-side edit (censor / caption-fix / caption-replace / trim / apply)
opusclip edit-clip censor --project PROJECT_ID --clip CLIP_ID --beep

# Wait for the re-render
while :; do
  opusclip describe --project PROJECT_ID --clip CLIP_ID \
    | jq -e '.renderAsVideoFile.pending == false' >/dev/null && break
  sleep 10
done

# Post the edited clip
opusclip post publish --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "..."
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video
- Thumbnail API: credit-charged per call (Pro/Enterprise only; Statsig-configured amount); experimental, may be disabled without notice (503)

## API Reference

For detailed endpoint schemas, parameters, and response formats, see [references/api-reference.md](references/api-reference.md).
