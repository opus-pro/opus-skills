# opus-skills

Agent skills for [OpusClip](https://opus.pro) — installable in Claude Code, Cursor, and other AI coding agents.

## Available Skills

| Skill | Description |
|-------|-------------|
| [opusclip](skills/opusclip/) | Turn long-form videos into short clips and post them to social platforms via the OpusClip API |

## Installation

```bash
# Install with npx
npx skills add opus-pro/opus-skills --skill opusclip

# Or install all skills
npx skills add opus-pro/opus-skills --all
```

### Manual installation

```bash
git clone https://github.com/opus-pro/opus-skills.git
cp -r opus-skills/skills/opusclip ~/.claude/skills/opusclip
```

## Prerequisites

- `OPUSCLIP_API_KEY` — API access requires an [Enterprise plan](https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus)
- `curl` and `jq` installed
- `ffmpeg` (optional, for storyboard and trim commands)

## What You Can Do

- **Clip videos** — submit YouTube/Vimeo/uploaded videos for AI-powered clipping
- **Review clips** — list, describe, preview, and storyboard generated clips
- **Organize** — manage collections, apply brand templates, censor profanity
- **Post to social** — publish or schedule clips to YouTube, TikTok, Facebook, Instagram, LinkedIn, and X

## License

MIT
