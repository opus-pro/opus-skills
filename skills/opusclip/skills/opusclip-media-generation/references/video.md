# Video

`kind: "video"` generates a short clip with MiniMax H3 (`model: "hailuo-3"`, also called Hailuo 3) or Dreamina Seedance 2.5 (`model: "seedance-2.5"`). Use it only when the tool's `kind` accepts `video`; otherwise tell the user video generation is not available and continue without it. Where this file and the tool's schema or description differ, follow the tool.

Read the provider guides for prompting: MiniMax [video generation](https://platform.minimax.io/docs/guides/video-generation) and [H3 feature highlights](https://platform.minimax.io/docs/guides/video-prompt); Seedance on [ModelArk](https://docs.byteplus.com/en/docs/ModelArk/2607688), its [prompt guide](https://docs.byteplus.com/en/docs/ModelArk/2607689) and the [task API](https://docs.byteplus.com/en/docs/modelark/create-video-generation-task-api). Some of these pages need JavaScript; if one does not render, use this file and the tool's validation errors.

## Choose a model

- `hailuo-3` by default: clips of 5-15 seconds at `768p` or `2k`.
- `seedance-2.5` for clips of 16-30 seconds, or when the clip needs its own dialogue, music or sound effects (`generateAudio: true`).
- Seedance rejects images that show a real person's face. Use `hailuo-3` for a first frame taken from footage of a person.

Generate only the shots the edit needs, one shot per clip. Do not replace the user's own footage with generated clips.

## Fields

| Field | `hailuo-3` | `seedance-2.5` |
|---|---|---|
| `prompt` | Required | Required |
| `durationSeconds` | Required, 5-15 | Required, 4-30 |
| `resolution` | `768p` (default) or `2k` | `480p` or `720p` (default) |
| `aspectRatio` | `16:9` (default), `9:16`, `1:1`, `4:3`, `3:4`, `21:9` | same |
| `firstFrameUrl` | Optional | Optional |
| `lastFrameUrl` | Optional, needs `firstFrameUrl` | Check the schema |
| `generateAudio` | Not available | Optional, default silent |

Use the field names and nesting in the tool's input schema; some options may sit inside `modelParams`, which accepts only the keys allowed for the chosen model. A wrong key or value is refused with the allowed values, before anything is charged.

Leave `aspectRatio` out when you send `firstFrameUrl`; the frame's shape sets it. Otherwise set it explicitly for the edit, such as `9:16` for a vertical short. Frame images must be public HTTPS URLs the user already hosts. Local files are not supported; never upload the user's files to a third-party host to get a URL.

Price grows with duration and resolution, so a longer or sharper clip is a new request with a new quote. A clip usually takes several minutes.

Billing and error codes for video follow the tool's own description. If it says the actual cost is charged and the rest refunded, count `chargedCredits` from the receipt, not the estimate, and follow any video-specific `errorCode` actions it lists. Quote and approve exactly as for speech and music.

## Write the prompt

Describe one shot: subject, action, scene, style, lighting, camera movement and, when relevant, sound. Be concrete about what moves and how: "slow push-in on a ceramic mug on a sunlit desk, steam rising, shallow depth of field, warm morning light". For a timed beat, give times inside the clip, such as "0-2s: ..., 2-5s: ...". With a first frame, describe the motion from that frame rather than the frame itself. With Seedance and `generateAudio: true`, follow its prompt guide for dialogue, music and effects, and put spoken lines in double quotes.

Do not ask for real people, brands, logos or copyrighted characters. When copying a video's style, describe the treatment, such as framing, motion and color, never the reference's footage.

## Provider docs to tool fields

| In the provider docs | Send |
|---|---|
| `model` `MiniMax-H3` | `model: "hailuo-3"` |
| `model` `dreamina-seedance-2-5-260628` | `model: "seedance-2.5"` |
| `text` content item | `prompt` |
| `duration` | `durationSeconds` (no model-chosen length) |
| `resolution` `768P`, `2K`, `720p` | `resolution` `768p`, `2k`, `720p` |
| `ratio` | `aspectRatio` |
| content role `first_frame` | `firstFrameUrl` |
| content role `last_frame` (MiniMax) | `lastFrameUrl` |
| `generate_audio` (Seedance) | `generateAudio` |
| reference images, video or audio, seed, watermark, draft, callback, H3-Max, 1080p | not offered unless the tool's schema lists them |

## Check the result

Read `outputs[0].mimeType` and `durationSeconds`. After download, run `ffprobe` for duration, dimensions, codec, frame rate and audio streams. Extract and view frames at the start, middle and end, and check them against the prompt, the aspect ratio and the first frame. A clip may carry an audio track you did not ask for; mute or replace it in the edit. Give the user the URL to watch before you cut it in.
