---
name: opusclip
description: Turn long-form videos into short clips and post them to social platforms using the OpusClip API. Use when the user wants to clip a YouTube video, upload a local video for clipping, manage clip collections, list brand templates, share projects publicly, censor profanity, post clips to social media, schedule social posts, or any task involving OpusClip. Triggers on phrases like "clip this video", "create shorts", "opusclip", "make clips from video", "upload to opusclip", "post to youtube", "schedule post", "publish clip".
---

# OpusClip

Turn long-form videos into short clips via the OpusClip API.

## Prerequisites

- `OPUSCLIP_API_KEY` must be set. Copy from https://clip.opus.pro/dashboard with an [Enterprise plan](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus).
- `curl` and `jq` on PATH. `ffmpeg` is also needed for `storyboard` and `trim`.

## CLI commands

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

Note: `upload --file` reads from the host filesystem, so it only works on hosts with shell access (Claude Code, Codex CLI/App, OpenClaw). Hosted Claude.ai / Cowork can't access local files; use a public URL with `submit --url` instead.

## Common workflows

### Clip a YouTube video
```
opusclip submit --url "https://youtube.com/watch?v=..."
opusclip list --project ID --summary
```

### Use ClipAnything with a custom prompt
```
opusclip submit --url "https://youtube.com/watch?v=..." \
  --model ClipAnything \
  --prompt "Find the most emotional moments" \
  --durations "30,60,90"
```

### Upload a local file, clip, and organize into a collection
```
opusclip upload --file /abs/path/video.mp4 --title "Interview" --model ClipBasic
opusclip list --project PROJECT_ID
opusclip collections create --name "Best Clips"
opusclip collections add-clip --id COL_ID --content-id PROJECT_ID.CLIP_ID
opusclip collections export --id COL_ID
```

### Clip, generate copy, post to social
```
opusclip submit --url "..."
opusclip list --project PROJECT_ID --summary
opusclip post accounts
opusclip post generate-copy --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --prompt "witty"
opusclip post copy-status --job JOB_ID
opusclip post publish --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "..."
# or schedule:
opusclip post schedule --project PROJECT_ID --clip CLIP_ID --account ACCOUNT_ID --title "..." --at "2026-03-25T14:00:00Z"
```

## Constraints

- Rate limit: 30 req/min
- Max video: 10 hours, 30 GB
- Max concurrent: 50 projects
- Projects expire after 30 days
- 1 credit = 1 minute of video

## API reference

For detailed endpoint schemas, request/response shapes, and edge cases, see [references/api-reference.md](references/api-reference.md).
