# Reference Analysis

Prepare the reference, scan it locally for free, and run OpusClip deep understanding only when the user chooses it. Commands are FFmpeg and yt-dlp examples for a POSIX shell; adapt paths, quoting and tools to the environment. Keep work files in the output directory, not beside the user's originals.

## Preflight

Before planning a style, check what can actually render. Homebrew's `ffmpeg-full` is keg-only: installing it does not put it on PATH, so a bare `ffmpeg` still runs the default build. Look for it by path:

```bash
FFMPEG=ffmpeg; FFPROBE=ffprobe
full="$(brew --prefix ffmpeg-full 2>/dev/null)"
if [ -n "$full" ] && [ -x "$full/bin/ffmpeg" ]; then FFMPEG="$full/bin/ffmpeg"; FFPROBE="$full/bin/ffprobe"; fi
"$FFMPEG" -hide_banner -version | head -n 1
"$FFMPEG" -hide_banner -filters | grep -E ' (subtitles|ass|drawtext|scdet|tile|ebur128|silencedetect|showspectrumpic|showwavespic) '
command -v yt-dlp
```

`subtitles` and `ass` (libass) render styled captions; `drawtext` (freetype) draws text. Homebrew's default `ffmpeg` formula builds without them; `brew install ffmpeg-full` adds them. Use `"$FFMPEG"` and `"$FFPROBE"` for caption and text rendering. Every command below uses these variables. Ask before installing anything; the what-to-copy round can carry that consent, and the host may still ask to approve the command. If no text renderer is available, use another installed renderer, or tell the user which caption treatment cannot be reproduced before planning around it.

## Get the reference as an MP4

A YouTube, TikTok or Instagram link is a page, not a media file, and the understanding tool does not resolve pages. Download the reference for local analysis only, then normalize it to H.264/AAC MP4. Keep the audio: the local loudness and spectrum checks read it, and deep understanding hears it.

```bash
mkdir -p work/frames
src="$(yt-dlp -f 'bv*+ba/b' --merge-output-format mp4 --no-playlist \
  -o 'work/reference-src.%(ext)s' --print after_move:filepath "$URL")"
"$FFMPEG" -i "$src" -t 300 -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -fps_mode cfr \
  -c:a aac -b:a 160k -movflags +faststart work/reference.mp4
"$FFPROBE" -v error -show_entries format=duration -of csv=p=0 work/reference.mp4   # durationSeconds
shasum -a 256 work/reference.mp4                                                  # sha256sum on Linux
```

Always re-encode when trimming; a `-c copy` cut lands on keyframes and can leave wrong frame counts. For a reference over 300 seconds, keep the section that carries the style (`-ss START -t 300`).

Codex's default sandbox has no network, so `yt-dlp`, installs, uploads and asset downloads need the user's approval. If a site needs a login, cookies, payment or a captcha, ask the user to download the file and share its path. Do not bypass DRM.

## Scan locally

The scan is free and runs before the what-to-copy question. You choose the sampling. Spend images where the style changes, and record the base rate, burst windows and reasons in `analysis.json`. View images with the host's image viewer: `Read` in Claude Code, `view_image` in Codex.

1. **Cuts.** Text output only, no images:

   ```bash
   "$FFMPEG" -hide_banner -i work/reference.mp4 -an -vf "scdet=threshold=10,metadata=print:key=lavfi.scd.time:file=work/cuts.txt" -f null -
   grep -o 'pts_time:[0-9.]*' work/cuts.txt | cut -d: -f2
   ```

   Derive the shot count and the median and shortest shot. Lower the threshold for soft footage and raise it for noisy handheld footage. `scdet` misses dissolves, whips and slow zooms. To find them, rerun with `metadata=print:file=work/scd_all.txt` (no `key`), which logs every frame's `lavfi.scd.mafd` and `lavfi.scd.score`. A run of raised `mafd` with no single score spike marks a soft transition or a fast camera move; burst it.

2. **Contact sheets** over the whole reference. Choose the base rate from the measured cadence: about 2 frames per median shot (2 / median shot seconds), clamped to 0.5-4 fps, and no more than about 120 frames in total. For a long reference, lower the rate and rely on bursts.

   ```bash
   "$FFMPEG" -i work/reference.mp4 -an -vf "fps=$RATE,scale=304:-2,tile=5x4" work/frames/sheet_%03d.jpg   # wider than 4:3 (16:9 -> 1520x688)
   "$FFMPEG" -i work/reference.mp4 -an -vf "fps=$RATE,scale=240:-2,tile=6x3" work/frames/sheet_%03d.jpg   # 4:3 or square (at most 1440x720)
   "$FFMPEG" -i work/reference.mp4 -an -vf "fps=$RATE,scale=-2:270,tile=6x3" work/frames/sheet_%03d.jpg   # 4:5 or 3:4 (at most 1296x810)
   "$FFMPEG" -i work/reference.mp4 -an -vf "fps=$RATE,scale=-2:288,tile=8x3" work/frames/sheet_%03d.jpg   # 9:16 (1296x864)
   ```

   Tile *n* (from 1, left to right, top to bottom) of sheet *k* shows about `((k-1) x tiles per sheet + n - 1) / rate` seconds. Keep this mapping; timestamps are not burned in.

3. **Native-frame bursts** where change is faster than the sheets: every frame of a short window, tiled into one image.

   ```bash
   "$FFMPEG" -ss 12.4 -t 1 -i work/reference.mp4 -an -vf "scale=256:-2,tile=6x5" -frames:v 1 work/frames/burst_012.4.jpg   # landscape or square
   "$FFMPEG" -ss 12.4 -t 1 -i work/reference.mp4 -an -vf "scale=-2:240,tile=8x4" -frames:v 1 work/frames/burst_012.4.jpg   # vertical
   ```

   Keep `-t` before `-i`: as an output option it does not limit what `tile` reads. A 1-second window at 30 fps fills the landscape tile; for a faster source, add `fps=30` first or shorten `-t`. Put the start time in the file name. Run steps 4 and 5 before choosing windows. Choose windows in this order until the budget is spent: the first 3 seconds; one or two instances of each transition type, including soft transitions found from `mafd`; caption entrances and changes from step 4; punch-ins and speed changes; loudness jumps, silences and sharp transients from step 5; and the last 2 seconds. Burst representative instances of a recurring pattern, not every cut. For caption type and color, also view one frame at up to 1,568 px: `"$FFMPEG" -ss 12.6 -i work/reference.mp4 -frames:v 1 -vf "scale='min(iw,1568)':'min(ih,1568)':force_original_aspect_ratio=decrease" work/frames/full_012.6.png`. For small text, crop the caption band at native size instead, for example `-vf "crop=iw:ih/4:0:ih*0.65"`.

4. **Caption changes.** Once a sheet shows where captions sit, run the cut detector on that band alone, with a low threshold, and move the crop to the band you saw. Motion inside the band also triggers it, so treat hits as candidates for bursts:

   ```bash
   "$FFMPEG" -hide_banner -i work/reference.mp4 -an -vf "crop=iw:ih/4:0:ih*0.65,scdet=threshold=4,metadata=print:key=lavfi.scd.time:file=work/caption_changes.txt" -f null -
   ```

5. **Sound**, read from pictures and measurements:

   ```bash
   "$FFMPEG" -i work/reference.mp4 -lavfi "showspectrumpic=s=1280x360:legend=1:fscale=log" work/frames/spectrum.png
   "$FFMPEG" -i work/reference.mp4 -lavfi "showwavespic=s=1568x240" -frames:v 1 work/frames/wave.png
   "$FFMPEG" -nostats -i work/reference.mp4 -vn -af "silencedetect=n=-35dB:d=0.3,ebur128=framelog=quiet" -f null - 2>&1 \
     | grep -E 'silence_(start|end)|^ +(I|LRA):'
   ```

   You cannot hear the reference. The spectrum picture has a time axis; with the waveform it places sections, drops, silences and transients, but it does not tell you genre, instruments, voice tone or lyrics. Do not describe those as observed unless deep understanding reported them. Confirm beat positions against transients before cutting on them.

**Image budget.** A tiled image costs about as much to view as one ordinary screenshot. Claude downscales images whose long edge exceeds about 1,568 px or whose area exceeds about 1.15 megapixels, and other hosts have their own limits. The sheet, burst and sound recipes stay under 1,568 px for the aspect each is labeled for, and the full-size frame recipe is capped the same way; crop to a region at native resolution when small text matters. Aim for about 6 sheets, 12-16 bursts and 2 sound pictures before asking. After the user chooses, add focused bursts only for the chosen elements and for analysis claims you will rely on, and stop when new images stop changing the style map.

## Understanding prompt

Run deep understanding only when the user chose it in the what-to-copy round, or asked for it. It usually costs a few credits per reference: each call holds 15 credits while running and charges only the actual cost. Make one call per reference; a changed prompt is a new, separately charged call.

Upload `work/reference.mp4` with `opusclip_create_upload_link`, complete the upload it describes, and pass the `UPL_...` ID as `uploadId`. Use `mediaUrl` only for a direct HTTPS media file the service can fetch (about 15 MiB at most); never make private footage public to get one. Pass the measured duration of the file you upload.

The prompt reaches the model as written and the result is free text, so ask for the exact plain-text layout you want. Fill in the braces and keep the whole prompt under 8,000 characters. When there are more than about 150 cuts, give the shot count and median shot length instead of the list. Leave `fps` at its default 1, or use 2 for a short, fast-cut reference; local bursts catch frame-level detail at no charge. Raise `maxOutputTokens` (up to 16,384) for long or dense references so the timeline is not cut off.

```text
You are helping a video editor recreate the editing style of this reference on different footage. Describe only what you can see or hear in this file. Give times as MM:SS.s from the start of the file. Fast events may fall between the frames you sampled: give your best time and mark it approximate. Quote on-screen text exactly. If a category is absent, write "none observed"; do not guess to fill a section. Describe people by role and framing only, and music by genre, instruments and energy; do not identify people or name songs or artists.

Editor's goal: {{what the user wants}}
Elements to copy, describe these in the most detail: {{the elements the user chose}}
Target footage: {{e.g. "9:16 talking head, 75 s, one speaker, no music"}}
Measured locally, trust these over your own estimates: hard cuts at {{cut times in seconds, or "N shots, median X s"}}

Answer in plain text with exactly these five sections.

1. OVERVIEW
Aspect ratio, length, format or genre, and the overall structure in 3-6 lines.

2. TIMELINE
One line per event, in time order:
MM:SS.s | type | what happens | confidence high/medium/low
Types: cut, transition, caption, title, graphic, zoom, speed, color, music, sfx, voice, other.
Include every shot change and transition you can perceive, every on-screen text change, every graphic or sticker entrance, every punch-in or zoom, every speed change, and every distinct music or sound-effect moment.

3. ELEMENTS
For each item, describe the recurring pattern with 1-3 example times, or write "none observed":
- Opening (first 3 s) and ending
- Pacing: typical and shortest shot length, fastest stretch, what cuts land on (phrase ends, beats, actions)
- Transitions: each kind used (hard cut, jump cut, J/L cut, match cut, whip, zoom, flash, dip, dissolve, glitch, wipe, mask reveal), its approximate length and how often
- Framing and camera: subject placement, punch-ins and how far, push-ins, shake, split screen or picture-in-picture, B-roll or screen-recording cutaways
- Captions: word-by-word, phrase or sentence; words per line and number of lines; position; font style (weight, case, serif or sans); colors; outline, shadow or box; keyword highlighting; emoji; entrance and exit animation
- Titles and graphics: lower thirds, callouts, arrows, stickers, progress bars, logos, textures or overlays
- Color and look: contrast, saturation, warmth, grain, vignette, grade changes between sections
- Speed: ramps, slow motion, freeze frames, reversals
- Music: genre and instruments, tempo estimate (label it an estimate), sections, builds and drops with times, whether cuts land on beats
- Sound effects: each kind, its timing, and the visual event it accompanies
- Voice: on-camera speech or voiceover, pace, whether pauses are trimmed, music level under speech
- Format: where subject and captions sit relative to platform interface safe zones, end card

4. RECIPE
The 5-10 rules an editor should follow to recreate this style on other footage, most important first, each pointing to evidence above.

5. LOOK CLOSER
Up to 8 signature moments where the style is most visible, then what you could not determine reliably (exact transition or caption animation frames, beat positions, small text), each with a time.
```

Only when the user chose understanding for their footage too: for the user's footage, replace sections 2 and 3 with a timecoded log of spoken phrases, actions, usable moments and existing on-screen text or logos, and drop section 4. Burst the LOOK CLOSER moments locally before relying on them.

## Persist the analysis

Write `analysis.json` in the output directory after the scan. If deep understanding runs, add the call as soon as a receipt returns, before polling, and update it as results arrive:

```json
{
  "reference": {
    "source": "<original link or path>",
    "file": "work/reference.mp4",
    "sha256": "<hex>",
    "durationSeconds": 58.4
  },
  "local": {
    "baseRate": 1.2,
    "cuts": "work/cuts.txt",
    "bursts": [{ "start": 12.4, "why": "raised mafd run near 12.5 s, likely whip" }]
  },
  "calls": [
    {
      "purpose": "deep understanding",
      "idempotencyKey": "cvs-<16 hex>-<8 hex>",
      "uploadId": "UPL_...",
      "params": { "mediaType": "video", "fps": 1, "maxOutputTokens": 8192 },
      "prompt": "<exact prompt sent>",
      "jobId": "<from the receipt>",
      "status": "<as last returned>",
      "chargedCredits": null,
      "resultText": "<result.text once complete>"
    }
  ]
}
```

Derive the idempotency key from the media and the request: `cvs-<first 16 hex of the media sha256>-<first 8 hex of the sha256 of prompt plus parameters>`. Reuse it only together with the saved `uploadId`; if the server reports a key conflict, look for the original receipt by `jobId` before any new submission. After a terminal failure whose billing has settled, append `-r2`, `-r3` for a new attempt. When billing is pending or uncertain, do not resubmit: report the `jobId` for operator review. Before any new call, read `analysis.json`. If the media hash, prompt and parameters match, reuse `resultText`, or poll `opusclip_get_reference_analysis` with the saved `jobId` if the job was still running.
