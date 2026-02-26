---
name: opusclip
description: Turn long-form videos into short clips using the OpusClip API. Use when the user wants to clip a YouTube video, upload a local video for clipping, manage clip collections, list brand templates, share projects publicly, censor profanity, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "upload to opusclip".
---

# OpusClip

Turn long-form videos into short clips via the OpusClip API.

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. Get it from https://clip.opus.pro/dashboard
- The CLI at `scripts/opusclip` requires `curl` and `jq`

## CLI Quick Reference

Run the bundled CLI at `scripts/opusclip`. All commands output JSON.

```
opusclip create-project --url URL [options]   Create clips from a video URL
opusclip get-clips --project ID               Get exportable clips
opusclip share-project --project ID           Set visibility (PUBLIC/DEFAULT)
opusclip templates                            List brand templates
opusclip upload --file PATH [options]         Upload local video + create project
opusclip collections <sub> [options]          Manage collections
opusclip censor <sub> [options]               Censor profanity in clips
```

### create-project

```bash
opusclip create-project --url "https://youtube.com/watch?v=..." [options]
```

| Flag | Description |
|------|-------------|
| `--url` | (required) Video URL |
| `--model` | `ClipBasic` (talking-head) or `ClipAnything` (diverse) |
| `--prompt` | Custom clipping prompt (ClipAnything only) |
| `--keywords` | Comma-separated topic keywords (ClipBasic only) |
| `--aspect` | `portrait` (default), `landscape`, `square` |
| `--durations` | Target clip lengths in seconds, e.g. `"30,60"` |
| `--range-start` / `--range-end` | Clip only a portion (seconds) |
| `--template` | Brand template ID |
| `--genre` | Video genre hint |
| `--lang` | Source language code |
| `--title` | Video title metadata |
| `--webhook` | Webhook URL for completion notification |
| `--skip-curate` | Process original video without AI curation |
| `--remove-filler` | Remove filler words |

### upload

Same flags as `create-project` plus `--file PATH`. Handles the full 4-step GCS upload flow automatically.

### get-clips

```bash
opusclip get-clips --project PROJECT_ID
opusclip get-clips --collection COLLECTION_ID
```

### collections

```bash
opusclip collections list
opusclip collections create --name "NAME"
opusclip collections delete --id ID
opusclip collections export --id ID
opusclip collections add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collections remove-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
```

### censor

```bash
opusclip censor create --project PID --clip CID [--beep]
opusclip censor status --job JOB_ID
```

Statuses: `QUEUED` → `PROCESSING` → `CONCLUDED` / `FAILED`

## Common Workflows

### Clip a YouTube video
```bash
opusclip create-project --url "https://youtube.com/watch?v=VIDEO_ID"
# Wait for processing, then:
opusclip get-clips --project PROJECT_ID
```

### Use ClipAnything with a custom prompt
```bash
opusclip create-project \
  --url "https://youtube.com/watch?v=VIDEO_ID" \
  --model ClipAnything \
  --prompt "Find the most emotional moments" \
  --durations "30,60,90"
```

### Upload a local video, clip, and organize
```bash
opusclip upload --file video.mp4 --title "Interview" --model ClipBasic
opusclip get-clips --project PROJECT_ID
opusclip collections create --name "Best Clips"
opusclip collections add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collections export --id COL_ID
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video

## API Reference

For detailed endpoint schemas, parameters, and response formats, see [references/api-reference.md](references/api-reference.md).
