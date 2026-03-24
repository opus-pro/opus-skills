# opus-skills

A skill marketplace for [OpusClip](https://opus.pro) — add video clipping, social posting, and more to your AI coding agent.

Install individual skills or the entire collection into Claude Code, Cursor, and other AI coding agents that support skills.

## Available Skills

| Skill | Description |
|-------|-------------|
| [opusclip](skills/opusclip/) | Turn long-form videos into short clips and post them to social platforms via the OpusClip API |

## Installation

In Claude Code, run:

```
/plugin marketplace add opus-pro/opus-skills
/plugin install opusclip
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

## Contributing

Want to add a new skill? Each skill lives in its own directory under `skills/`. See [skills/opusclip](skills/opusclip/) for an example of the structure.

## License

MIT
