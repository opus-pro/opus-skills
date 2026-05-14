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
opusclip edit-clip caption-fix --project P --clip C \
  --find "prooduct" --replace "product"
# add --ignore-case for case-insensitive
```

Equivalent power-user form:

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
    if (.sections // []) | length > 0 and (.sections[0].sectionTimeline // null) != null then
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

- **Extend** (setting `sectionTimeline.out > sourceDurationMs`). `edit-clip trim` will warn but still send the request. The engine may freeze-last-frame, silently clamp, or error.
- Re-render of clips that originated from non-`skipCurate` flows (multi-clip projects) was verified once and works the same way, but the editingScript will have more tracks (BRoll, etc.) — leave the ones you're not editing untouched.

## Reference

- Endpoint reference: `references/api-reference.md`
- Web editor (uses the same `editingScript` shape via Save action): `apps/clip-web/src/api/useCuratedClipApi.ts:160-192` in the clip-apps repo.
