# opus-skills

Agent skills for [OpusClip](https://opus.pro) — installable in Claude Code, Cursor, and other AI coding agents.

## Available Skills

| Skill | Description |
|-------|-------------|
| [opusclip](skills/opusclip/) | Turn long-form videos into short clips via the OpusClip API |

## Installation

```bash
# Install with npx
npx skills add yong-opus/opus-skills --skill opusclip

# Or install all skills
npx skills add yong-opus/opus-skills --all
```

### Manual installation

```bash
git clone https://github.com/yong-opus/opus-skills.git
cp -r opus-skills/skills/opusclip ~/.claude/skills/opusclip
```

## Prerequisites

- `OPUSCLIP_API_KEY` — get yours at https://clip.opus.pro/dashboard
- `curl` and `jq` installed

## License

MIT
