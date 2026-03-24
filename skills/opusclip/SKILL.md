---
name: opusclip
description: Turn long-form videos into short clips and post them to social platforms using the OpusClip API. Use when the user wants to clip a YouTube video, manage clip collections, list brand templates, share projects publicly, censor profanity, post clips to social media, schedule social posts, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "post to youtube", "schedule post", "publish clip".
---

# OpusClip

Turn long-form videos into short clips and post them to social platforms via the OpusClip API.

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. Get it from https://clip.opus.pro/dashboard
- The CLI at `scripts/opusclip` requires `curl` and `jq`

## CLI Quick Reference

Run the bundled CLI at `scripts/opusclip`. All commands output JSON.

```
opusclip submit --url URL [options]           Submit video for clipping
opusclip list --project ID [--summary]        List clips
opusclip share --project ID                   Share project
opusclip templates                            List brand templates
opusclip collections <sub> [options]          Manage collections
opusclip censor <sub> [options]               Censor profanity in clips
opusclip post <sub> [options]                 Social posting
```

### submit

```bash
opusclip submit --url "https://youtube.com/watch?v=..." [options]
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

### list

```bash
opusclip list --project PROJECT_ID
opusclip list --project PROJECT_ID --summary
opusclip list --collection COLLECTION_ID
```

| Flag | Description |
|------|-------------|
| `--project` | Project ID to fetch clips for |
| `--collection` | Collection ID to fetch clips for |
| `--summary` | Condensed JSON with title, description, hashtags, scores, duration |

When presenting clips to the user, always use `--summary` to get human-readable fields.

### share

```bash
opusclip share --project PROJECT_ID
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

### post

Publish clips to YouTube, TikTok, Facebook, Instagram, LinkedIn, and X.

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
| `schedule` | Schedule a clip for future publishing |
| `cancel` | Cancel a scheduled post |

Each X post costs 1 credit.

## Common Workflows

### Clip a YouTube video
```bash
opusclip submit --url "https://youtube.com/watch?v=VIDEO_ID"
# Wait for processing, then:
opusclip list --project PROJECT_ID --summary
```

### Clip and post to social
```bash
opusclip submit --url "https://youtube.com/watch?v=..."
opusclip list --project PROJECT_ID --summary
opusclip post accounts
opusclip post generate-copy --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID
opusclip post copy-status --job JOB_ID
opusclip post publish --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "Check this out!"
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video

## API Reference

For detailed endpoint schemas, parameters, and response formats, see [references/api-reference.md](references/api-reference.md).
