# EditingScript Round-Trip

Server-side edits to an existing clip — fix typos, trim, restyle — flow through one primitive: send back the edited `EditingScript` and the engine re-renders.

## TL;DR

```
GET  /api/exportable-clips/:clipFullId?include=editingScript
       ↓ returns the clip + the full EditingScript JSON (~7 KB)
       ↓ mutate locally
POST /api/exportable-clips/:clipFullId/re-render
       body: { editingScript: <edited JSON>, renderPreferenceOverride?: {...} }
       ↓ engine compiles + re-renders
GET  /api/exportable-clips/:clipFullId
       ↓ poll until renderAsVideoFile.pending === false
       ↓ uriForExport now points at the new mp4
```

The CLI's `opusclip edit-clip` umbrella wraps exactly this pattern. Five sub-verbs — `get`, `apply`, `caption-fix`, `caption-replace`, `trim` — all hit the same primitive. `apply --script <file>` is the escape hatch: any edit the web editor supports, an API consumer can do.

## Which sub-verb fits which input?

When the user wants to "re-render with new captions" or similar phrasing, pick by what they have in hand:

| User has… | Use |
|-----------|-----|
| A transcript JSON (`{segments: [...]}`) | `edit-clip caption-replace --transcript file.json` |
| An edited EditingScript JSON | `edit-clip apply --script file.json` |
| A single find/replace string pair | `edit-clip caption-fix --find X --replace Y` |
| A new in/out window in seconds | `edit-clip trim --start S --end E` |
| None of the above — wants to inspect first | `edit-clip get --output script.json` |

## EditingScript shape (the parts you'll actually touch)

```jsonc
{
  "modelVersions": { /* engine internals — leave alone */ },
  "tracks": [
    {
      "id": "...",
      "trackType": "KeyFrameTrack",      // video frames
      "sections": [
        {
          "id": "...",
          "sectionTimeline": { "in": 0, "out": 30000 },
          "sectionDuration": { "type": "TS", "sO": 0, "eO": 30000 },
          "segments": [ /* segments inside the section */ ]
        }
      ]
    },
    {
      "trackType": "CaptionTrack",       // burned-in captions
      "sections": [
        {
          "sectionTimeline": { "in": 0, "out": 30000 },
          "sectionDuration": { "type": "TS", "sO": 0, "eO": 30000 },
          "segments": [
            {
              "content": {
                "textElements": [        // ← this is where caption text lives
                  {
                    "id": "...",
                    "text": "Hello world",
                    "color": 0,
                    "timeline":  { "in": 500, "out": 1500 },
                    "duration":  { "type": "TS", "sO": 500, "eO": 1500 }
                  }
                ]
              }
            }
          ]
        }
      ]
    },
    {
      "trackType": "EmojiTrack",         // empty on most clips
      "sections": []
    }
  ]
}
```

Key things to remember:

- **Time is in milliseconds.** Both `timeline.in/out` and `duration.sO/eO`.
- **Most clips have 3 tracks** (KeyFrame + Caption + Emoji). Others (BRoll, ScreenOverlay, TextOverlay, etc.) appear only when the editor added them.
- **Section vs segment vs element timing.** `sectionTimeline` is the section's slot in the clip's timeline. `segment.timeline` is the segment within the section. `textElement.timeline` is the element within the segment. For simple typo fixes, only `textElement.text` matters.
- **EmojiTrack may have `sections: []`** — that's the no-emoji case. Don't error on missing fields.

## Recipe — fix a typo

Inside `tracks[trackType=="CaptionTrack"].sections[].segments[].content.textElements[]`, change `.text` on matching elements:

```bash
# Single-word fix — regex gsub on every textElement.text (matches inside words too).
opusclip edit-clip caption-fix --project P --clip C \
  --find "prooduct" --replace "product"
# add --ignore-case for case-insensitive

# Multi-word fix — caption-fix walks consecutive textElements and replaces 1:1.
# --replace must have the same word count as --find (each replacement token
# inherits the matched slot's per-word timing).
opusclip edit-clip caption-fix --project P --clip C \
  --find "2 lonely" --replace "Two lonely"
```

**Why the 1:1 constraint?** Caption tracks store every word as its own `TextElement` so per-word timing can drive the highlight animation. A multi-word `--find` matches a sliding window over the token sequence; replacement tokens overwrite the matched slots in place. Different-length rewrites (e.g. `"2"` → `"Two and a half"`) would force the CLI to invent or drop timing — use `caption-replace` (whole-track rewrite from a transcript) or `apply` (custom EditingScript edit) instead.

Equivalent power-user form (single-word, regex):

```bash
opusclip edit-clip get --project P --clip C --output script.json
jq '
  .tracks |= map(
    if .trackType=="CaptionTrack" then
      .sections |= map(.segments |= map(
        .content.textElements |= map(
          .text |= gsub("prooduct"; "product")
        )
      ))
    else . end
  )
' script.json > script.edit.json
opusclip edit-clip apply --project P --clip C --script script.edit.json
```

## Recipe — trim (shrink)

For every track section that has timing, set both `sectionTimeline.out` and `sectionDuration.eO` to the new end time:

```bash
opusclip edit-clip trim --project P --clip C --start 0 --end 15
# values are in seconds; use --start-ms / --end-ms for milliseconds
```

Equivalent power-user form:

```bash
opusclip edit-clip get --project P --clip C --output script.json
jq '
  .tracks |= map(
    if ((.sections // []) | length) > 0 and (.sections[0].sectionTimeline // null) != null then
      .sections[0].sectionTimeline.in  = 0
      | .sections[0].sectionTimeline.out = 15000
      | .sections[0].sectionDuration.sO = 0
      | .sections[0].sectionDuration.eO = 15000
    else . end
  )
' script.json > script.edit.json
opusclip edit-clip apply --project P --clip C --script script.edit.json
```

## Recipe — replace whole caption track

You bring a transcript file:

```json
{
  "segments": [
    { "text": "Hello world", "startMs": 0, "endMs": 1500,
      "words": [
        { "word": "Hello", "startMs": 0, "endMs": 700 },
        { "word": "world", "startMs": 800, "endMs": 1500 }
      ]
    }
  ]
}
```

```bash
opusclip edit-clip caption-replace --project P --clip C --transcript captions.json
```

`words` is optional — when omitted, each segment becomes one `TextElement` spanning `startMs..endMs`. Supply `words` for karaoke-style word-by-word highlighting.

## Polling

`POST /re-render` returns `{ jobId }` immediately. The clip's render is asynchronous:

```bash
# Watch both render targets
while :; do
  state=$(opusclip describe --project P --clip C | jq -r '
    "preview=\(.renderAsVideoPreview.pending // true) file=\(.renderAsVideoFile.pending // true)"')
  echo "$state"
  [[ "$state" == "preview=false file=false" ]] && break
  sleep 10
done
```

Or, more simply, poll until `uriForExport` changes (the new render publishes a new signed URL).

Typical re-render time on a 30 s clip: **~30–45 s** for both targets.

## What the engine handles for you

- Compiling EditingScript → low-level RenderPlan
- Applying brand template, font, watermark, animation, aspect ratio (preserved by construction unless you change them in the script)
- Storing the new editingScript as the source-of-truth for this clip's next edit
- Producing both `VIDEO_PREVIEW` and `VIDEO_FILE` targets

## What's *not* yet verified

- **Extend** (setting `sectionTimeline.out > sourceDurationMs`). The engine no-ops silently — `edit-clip trim` now clamps `--end` down to the current `durationMs` and reports the clamp via `clampedEndMs`/`note` in the response. Cross-source extends (lengthening past the source video) are out of scope.
- Re-render of clips that originated from non-`skipCurate` flows (multi-clip projects) was verified once and works the same way, but the editingScript will have more tracks (BRoll, etc.) — leave the ones you're not editing untouched.

## Reference

- Endpoint reference: `references/api-reference.md`
- Web editor (uses the same `editingScript` shape via Save action): `apps/clip-web/src/api/useCuratedClipApi.ts:160-192` in the clip-apps repo.
