# EditingScript Round-Trip

Server-side edits to an existing clip — fix typos, trim, swap captions — all flow through one primitive: fetch the clip's `EditingScript`, mutate it, send it back, and the server re-renders.

The CLI does **not** construct EditingScripts. You — the agent reading this — own the construction. The CLI gives you transport (`get` / `apply`) and a profanity-censor convenience (`censor`). This doc gives you the EditingScript shape and a worked sample for each common edit; you adapt them.

## TL;DR — the loop

```
opusclip clip edit get --project P --clip C --output current.json
       ↓ inspect current.json — confirm tracks, sections, ranges
       ↓ build edited.json by adapting one of the samples below
opusclip clip edit apply --project P --clip C --script edited.json
       ↓ returns { jobId } immediately
opusclip clip get --project P --clip C
       ↓ poll until renderAsVideoFile.pending == false
       ↓ uriForExport now points at the new mp4
```

Re-rendering is asynchronous and charged. A 30 s clip typically takes ~30–45 s for both `VIDEO_PREVIEW` and `VIDEO_FILE` to settle.

## Anatomy of an EditingScript

A clip's `editingScript` is a tree of tracks → sections → segments → elements. Time is in **milliseconds** throughout. Two coordinate systems coexist:

- **`duration.{sO, eO}` (and the optional `sOAdj`, `eOAdj` overrides) are source-media offsets** — milliseconds into the original upload/source video. They tell the renderer *which slice of the source* to use. If the optional `…Adj` fields are present, the renderer reads those in preference to the base `sO/eO` — so when you mutate a duration on a clip the renderer has already touched, set `sOAdj`/`eOAdj` rather than (or in addition to) `sO`/`eO`.
- **`timeline.{in, out}` is clip-relative output time** — milliseconds into the rendered mp4, starting at 0. It tells the renderer *where in the new clip to place this content*.

Mixing the two is the most common edit-script bug. Whenever you change a duration, ask: "does this affect what part of the source plays, or where in the output it plays?" — you usually need to touch both.

```jsonc
{
  "modelVersions": { /* engine internals — leave alone */ },
  "tracks": [
    {
      "trackType": "KeyFrameTrack",      // video frames + crop/layout
      "sections": [
        {
          "sectionTimeline": { "in": 0, "out": 30000 },                                  // output-relative
          "sectionDuration": { "type": "TS", "sO": 0, "eO": 30000 },                     // source-relative
          "segments": [
            {
              "duration": { "type": "TS", "sO": 0, "eO": 30000 },
              "timeline": { "in": 0, "out": 30000 },
              "content": {
                "keyFrameContents": [ /* per-keyframe items — each with their own duration + timeline */ ]
              }
            }
          ]
        }
      ]
    },
    {
      "trackType": "CaptionTrack",       // burned-in word-level captions
      "sections": [
        {
          "sectionTimeline": { "in": 0, "out": 30000 },
          "sectionDuration": { "type": "TS", "sO": 0, "eO": 30000 },
          "segments": [
            {
              "duration": { "type": "TS", "sO": 0, "eO": 30000 },
              "timeline": { "in": 0, "out": 30000 },
              "content": {
                "textElements": [        // ← one element per spoken word, with per-word timing
                  {
                    "id": "...",
                    "text": "Hello",
                    "color": 0,
                    "timeline": { "in":  0, "out":  500 },
                    "duration": { "type": "TS", "sO":  0, "eO":  500 }
                  },
                  {
                    "id": "...",
                    "text": "world",
                    "color": 0,
                    "timeline": { "in":  600, "out": 1200 },
                    "duration": { "type": "TS", "sO": 600, "eO": 1200 }
                  }
                ]
              }
            }
          ]
        }
      ]
    },
    {
      "trackType": "EmojiTrack",
      "sections": []                       // empty on most clips — the no-emoji case
    }
  ]
}
```

Things to remember:

- Three tracks are typical: `KeyFrameTrack`, `CaptionTrack`, `EmojiTrack`. Curated multi-clip projects also have `BRoll`, `ScreenOverlay`, `TextOverlay`, etc. — leave any track you're not editing untouched.
- `EmojiTrack` (and others) may have `sections: []`. Don't error on missing fields.
- `sectionTimeline` / `segment.timeline` / `textElement.timeline` are progressively-nested clip-output windows. `sectionDuration` / `segment.duration` / `textElement.duration` are source-media windows. They tend to match on a freshly-curated clip and diverge as edits accumulate.
- Sections originally produced by `skipCurate` typically have one section per timed track; clips from the curated-project pipeline can have several per track.

---

## Sample — fix a typo in the captions

Goal: change one word ("prooduct" → "product") wherever it appears in the captions, without changing timing.

Mutation: in every `tracks[trackType=="CaptionTrack"].sections[].segments[].content.textElements[]`, update `.text` on the matching elements. Leave `timeline` and `duration` alone.

Before (an excerpt of `.tracks[trackType=="CaptionTrack"].sections[0].segments[0].content.textElements`):

```jsonc
[
  { "text": "I",        "timeline": { "in":   0, "out":  200 }, "duration": { "type": "TS", "sO":   0, "eO":  200 } },
  { "text": "love",     "timeline": { "in": 300, "out":  700 }, "duration": { "type": "TS", "sO": 300, "eO":  700 } },
  { "text": "prooduct", "timeline": { "in": 800, "out": 1500 }, "duration": { "type": "TS", "sO": 800, "eO": 1500 } }
]
```

After:

```jsonc
[
  { "text": "I",       "timeline": { "in":   0, "out":  200 }, "duration": { "type": "TS", "sO":   0, "eO":  200 } },
  { "text": "love",    "timeline": { "in": 300, "out":  700 }, "duration": { "type": "TS", "sO": 300, "eO":  700 } },
  { "text": "product", "timeline": { "in": 800, "out": 1500 }, "duration": { "type": "TS", "sO": 800, "eO": 1500 } }
]
```

Worked jq for the single-word case (`gsub` runs over every `text` field, matching inside words too):

```bash
opusclip clip edit get --project P --clip C --output current.json
jq '
  .editingScript
  | .tracks |= map(
      if .trackType == "CaptionTrack" then
        .sections |= map(.segments |= map(
          .content.textElements |= map(.text |= gsub("prooduct"; "product"))
        ))
      else . end
    )
' current.json > edited.json
opusclip clip edit apply --project P --clip C --script edited.json
```

Notes:

- `gsub` matches inside words by default. Use `\\b` anchors if you want word-boundary matches.
- The CaptionTrack stores **every word as its own `TextElement`** so per-word timing can drive the highlight animation. To rewrite a multi-word phrase, walk consecutive elements in the same segment (or across segment boundaries if the phrase straddles them) and replace tokens 1:1 — each replacement inherits the matched slot's timing.
- Different-length rewrites (`"2"` → `"Two and a half"`) force you to invent or drop timing. Either spread the new text across the same slot count by manually picking timeline values, or use the whole-track replacement sample below.

---

## Sample — trim a clip (shrink the rendered mp4)

Goal: the user wants to shorten the clip — e.g. "trim from 3 s to 15 s" of a clip that's currently 0–18 s. Output should be 12 s long, and the captions, video, and audio should all reflect the new window.

This is the most subtle edit. The CLI used to ship a `trim` sub-verb that hand-rolled this; in v2.2.7 it was removed because it kept drifting from the engine's contract. The sample below is the same algorithm, but you (the agent) execute it with awareness of your specific clip's shape — which is more robust than a one-size-fits-all jq.

### What needs to change

For each section that has timed content (typically the first section of `KeyFrameTrack` and `CaptionTrack` — and any other track with a non-empty `sections` array):

1. **Compute the new source-media window.** The user's `--start` / `--end` are clip-relative ms. Read the section's current source range (`sectionDuration.sOAdj // sectionDuration.sO` for the start, same for end). Add the clip-relative offsets:
   - `newSrc.start = origSO + start_ms`
   - `newSrc.end   = origSO + end_ms`
2. **Update the section header.** Set `sectionDuration.sOAdj = newSrc.start` and `sectionDuration.eOAdj = newSrc.end` (writing the `Adj` variants ensures the renderer sees the new range even if it had previously stored its own override). Set `sectionTimeline.in = 0` and `sectionTimeline.out = end_ms - start_ms`.
3. **Filter and clamp each leaf.** Walk every `segments[]` in the section, and inside each segment walk `content.keyFrameContents[]` (for KeyFrameTrack) or `content.textElements[]` (for CaptionTrack). For every leaf, look at its `duration` in source coords. Apply two passes (start-trim then end-trim) so leaves spanning both ends get trimmed on both ends:

   For each pass with a target `(passStart, passEnd)`:
   - If the leaf's `[duration.sOAdj // sO, duration.eOAdj // eO]` is entirely outside `[passStart, passEnd]` → drop the leaf.
   - If it starts inside but ends after → set `duration.eOAdj = passEnd` (and, if `content.duration` exists on the leaf, do the same there).
   - If it starts before but ends inside → set `duration.sOAdj = passStart` (same `content.duration` propagation).
   - If it's entirely inside → leave it.

   First pass: `(newSrc.start, origEnd)`. Second pass: `(newSrc.start, newSrc.end)`. The two-pass structure is what handles a leaf whose original `[sO, eO]` straddles *both* ends of the new window.

4. **Remap each surviving leaf's `timeline`** to clip-relative output coords:
   - `timeline.in  = (post-clamp source start) - newSrc.start`
   - `timeline.out = (post-clamp source end)   - newSrc.start`

### Before / after

Original clip (curated, starts at source 98 s into a longer upload, runs 18 s):

```jsonc
{
  "trackType": "CaptionTrack",
  "sections": [{
    "sectionTimeline": { "in": 0, "out": 18000 },
    "sectionDuration": { "type": "TS", "sO": 98000, "eO": 116000, "sOAdj": 98000, "eOAdj": 116000 },
    "segments": [{
      "duration": { "type": "TS", "sO": 98000, "eO": 116000 },
      "timeline": { "in": 0, "out": 18000 },
      "content": {
        "textElements": [
          { "text": "before",         "duration": { "type": "TS", "sO":  98500, "eO":  99500 }, "timeline": { "in":   500, "out":  1500 } },
          { "text": "straddle-start", "duration": { "type": "TS", "sO": 100500, "eO": 101500 }, "timeline": { "in":  2500, "out":  3500 } },
          { "text": "middle",         "duration": { "type": "TS", "sO": 105000, "eO": 106000 }, "timeline": { "in":  7000, "out":  8000 } },
          { "text": "straddle-end",   "duration": { "type": "TS", "sO": 112500, "eO": 113500 }, "timeline": { "in": 14500, "out": 15500 } },
          { "text": "after",          "duration": { "type": "TS", "sO": 114000, "eO": 115000 }, "timeline": { "in": 16000, "out": 17000 } }
        ]
      }
    }]
  }]
}
```

User request: trim to clip-relative 3000 ms – 15000 ms.

Computation:

- `origSO = 98000`, `start_ms = 3000`, `end_ms = 15000`
- `newSrc = [98000 + 3000, 98000 + 15000] = [101000, 113000]`
- New clip duration = `15000 - 3000 = 12000` ms

After:

```jsonc
{
  "trackType": "CaptionTrack",
  "sections": [{
    "sectionTimeline": { "in": 0, "out": 12000 },
    "sectionDuration": { "type": "TS", "sO": 98000, "eO": 116000, "sOAdj": 101000, "eOAdj": 113000 },
    "segments": [{
      "duration": { "type": "TS", "sO": 98000, "eO": 116000, "sOAdj": 101000, "eOAdj": 113000 },
      "timeline": { "in": 0, "out": 12000 },
      "content": {
        "textElements": [
          // "before"         → wholly outside new window → dropped
          { "text": "straddle-start",
            "duration": { "type": "TS", "sO": 100500, "eO": 101500, "sOAdj": 101000 },
            "timeline": { "in":     0, "out":   500 } },
          { "text": "middle",
            "duration": { "type": "TS", "sO": 105000, "eO": 106000 },
            "timeline": { "in":  4000, "out":  5000 } },
          { "text": "straddle-end",
            "duration": { "type": "TS", "sO": 112500, "eO": 113500, "eOAdj": 113000 },
            "timeline": { "in": 11500, "out": 12000 } }
          // "after"          → wholly outside new window → dropped
        ]
      }
    }]
  }]
}
```

The same shape applies to `KeyFrameTrack` (walk `content.keyFrameContents` instead of `content.textElements`) and any other timed track in the script.

### Edge cases worth reading before you ship the edit

- **Multi-section clips.** Curated multi-clip projects can have several sections per track. The sample above handles only the first section. For multi-section clips, repeat the procedure for the relevant section(s) and then reflow `sectionTimeline.in` so later sections start at the previous section's `out` — otherwise the timeline has gaps.
- **Extends.** If `end_ms` is larger than the section's current source duration, the engine silently no-ops the extend and publishes the original mp4. Clamp `end_ms` to the clip's `durationMs` (available via `opusclip clip get`) before you do the math.
- **Empty sections after trimming.** If the new window doesn't intersect any leaf at all, you'll end up with an empty `segments[]`. That's a sign the user requested a range outside the clip's content — surface it as an error rather than submitting.

---

## Sample — replace the whole caption track

Goal: the user has a transcript JSON and wants the clip's captions wholly replaced (e.g. they generated new captions with their own model, or fixed punctuation across the board).

Their transcript looks like this:

```jsonc
{
  "segments": [
    { "text": "Hello world", "startMs": 0, "endMs": 1500,
      "words": [
        { "word": "Hello", "startMs":  0, "endMs":  700 },
        { "word": "world", "startMs": 800, "endMs": 1500 }
      ]
    },
    { "text": "How are you", "startMs": 1700, "endMs": 3000 }
  ]
}
```

Mutation: collapse the entire `CaptionTrack` to a single section with a single segment whose `content.textElements` is the flattened word list (or one element per segment when `words` is absent). Preserve the section's existing `sectionTimeline` / `sectionDuration` (the clip's overall duration doesn't change — only the words do).

Before (the original `CaptionTrack` — may have many sections, many segments, hundreds of textElements):

```jsonc
{
  "trackType": "CaptionTrack",
  "sections": [/* many sections, many segments */]
}
```

After:

```jsonc
{
  "trackType": "CaptionTrack",
  "sections": [{
    "sectionTimeline": { "in": 0, "out": 30000 },         // unchanged from the original section[0]
    "sectionDuration": { "type": "TS", "sO": 0, "eO": 30000 },
    "segments": [{
      "id": "caption-replace-segment",
      "content": {
        "textElements": [
          { "id": "cr-0-0", "text": "Hello", "color": 0,
            "duration": { "type": "TS", "sO": 0, "eO": 700 },
            "timeline": { "in":  0, "out":  700 } },
          { "id": "cr-0-1", "text": "world", "color": 0,
            "duration": { "type": "TS", "sO": 0, "eO": 700 },
            "timeline": { "in": 800, "out": 1500 } },
          { "id": "cr-1-0", "text": "How are you", "color": 0,
            "duration": { "type": "TS", "sO": 0, "eO": 1300 },
            "timeline": { "in": 1700, "out": 3000 } }
        ]
      }
    }]
  }]
}
```

Notes:

- When the segment has `words`, emit one `TextElement` per word — that's what drives the karaoke highlight animation.
- When `words` is absent, emit one `TextElement` per segment, spanning the segment's `startMs..endMs`.
- The `id` strings just need to be unique within the segment. The pattern above (`cr-<segIdx>-<wordIdx>`) is fine.
- Keep `sectionTimeline` and `sectionDuration` from the original first section — replacing captions doesn't change the clip's length.
- `color: 0` is the default caption color (the brand template applies its own palette downstream).

Submit via `opusclip clip edit apply --project P --clip C --script edited.json`.

---

## Polling and what the engine handles for you

`POST` to `apply` returns `{ jobId }` immediately. To wait for the re-render:

```bash
while :; do
  state=$(opusclip clip get --project P --clip C | jq -r '
    "preview=\(.renderAsVideoPreview.pending // true) file=\(.renderAsVideoFile.pending // true)"')
  echo "$state"
  [[ "$state" == "preview=false file=false" ]] && break
  sleep 10
done
```

The engine handles, for any edit:

- Compiling `EditingScript` → low-level render plan
- Applying the brand template, font, watermark, animation, aspect ratio (preserved by construction unless your edit touches them)
- Storing the new `editingScript` as the source-of-truth for this clip's next edit
- Producing both `VIDEO_PREVIEW` and `VIDEO_FILE` targets

## Reference

- Endpoint reference: `references/api-reference.md`
- For profanity censoring, prefer `opusclip clip edit censor --beep` — it calls a dedicated endpoint and doesn't require you to construct an `EditingScript`.
