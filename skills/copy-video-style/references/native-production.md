# Native Production and Verification

Use the chosen local renderer's supported features. The examples describe timing and media invariants rather than prescribing a renderer or an editing template.

## Gemini understanding call

Use these tools only when exposed in the session; a documented tool is not proof of runtime availability. `opusclip_list_media_models({task: "analysis"})` discovers models. `opusclip_get_media_model({modelId})` reads the current input schema/version; calling it with `task: "analysis"` and complete `inputs` gives a free pre-call quote. Preserve the returned `modelSchemaVersion`; do not hardcode a model or price version.

For a Gemini video model, inputs include `prompt`, `mediaUrl`, `mediaType: "video"`, and the actual `durationSeconds`; check the current schema for supported `fps`, `maxOutputTokens`, limits, and defaults. Probe the real source duration. A direct HTTPS media URL must be readable through the supported access mechanism. A local file needs an authorized upload/access path; do not pass its filesystem path as a URL or expose private footage publicly as an access workaround.

Start `opusclip_analyze_media` with `{modelId, modelSchemaVersion, idempotencyKey, inputs}` and optional `confirmedCredits`. The key is a stable unique string of 8–128 characters for this exact call. Reuse it only for an identical retry; a changed prompt/model/media is a new call. Normal billing does not require `confirmedCredits`; omit it unless a per-call price was actually shown and accepted. Do not introduce a budget or confirmation workflow.

Read the returned understanding text (`result.text`), usage (`result.usage`), durable `jobId`, and billing fields. Timing may be approximate because video sampling does not inspect every frame; verify claims with native frames/audio. For an uncertain result or pending settlement, retrieve the existing call with `opusclip_get_media_result({jobId})`; the lookup starts no new inference, but it may settle the original call's charges; it is not a guarantee of no wallet mutation. `pendingCredits` includes known supplementary charges above the wallet hold. `reservedCredits` is only the outstanding hold, and `chargedCredits: null` means unresolved, never zero. Report `chargedCredits` as actual only when settlement confirms it, and distinguish it from `estimatedCredits`, `pendingCredits`, and `confirmedCredits`. The receipt exposes credits, not a billed USD amount; do not derive actual billing from token usage or account API caps.

## A reproducible timeline

Store each retained source interval as source start/end plus output start/end and its crop/zoom settings. Record source frame dimensions, output canvas/aspect/frame rate, subtitle styling, audio settings, and the command/script needed to render. Keep source-media paths distinct from output paths. Bundle necessary sidecars and assets, or document the original media dependency so another editor can rerender it.

Use one time unit consistently in the saved plan and label it. For normal-speed interval `[s,e)` placed at output time `o`, a source event at `t` maps to `o + (t-s)`. Output interval length is `e-s`; the next output start follows the preceding interval end. If speed changes are supported and explicitly planned, timing, audio, and captions all need the same speed transform. Do not silently time-stretch speech to force a reference duration.

Check interval order, positive lengths, source bounds, intended omissions, and total output duration before rendering. Cuts can disrupt pronouns, explanations, breaths, gestures, or mouth shapes even when timestamps are valid. Prefer semantic word/phrase boundaries grounded in the actual footage. A very short cut may encode but still be unpleasant; inspect it rather than assuming it matches a rapid reference.

In FFmpeg, trim video/audio from the same source bounds and reset their timestamps before concatenation (`trim`/`setpts` and `atrim`/`asetpts`). Keep video/audio segment counts and order identical. Normalize differing dimensions/frame rates/audio formats deliberately if combining sources. Quote file paths and filter arguments safely; do not interpolate transcript text into shell code. Use subtitle files for caption content.

## Timed captions

Prefer an existing verified word-timed transcript; otherwise use available transcription/alignment and check it against the speech. Gemini can propose a transcript or timing, but its timestamps are hypotheses until verified. Retain original word times and create output times by mapping through the cut plan, removing words cut from the video. Check words that cross a cut instead of merely clipping their event windows.

A project-wide transcript may use original-source milliseconds while the local target is an extracted or assembled excerpt. Read the supplied extraction manifest/source-to-local mapping before declaring that transcript unmatched. Record the original source offset and any assembled cuts. Select overlapping words for each mapped source interval and place them at its local offset, then map through the new edit timeline. Do not use whole-source timestamps as local clip times. Missing offline ASR alone is not a reason to abandon supplied timed source data; verify its mapping and disclose any remaining alignment/listening uncertainty.

Group words into readable lines/phrases based on actual cadence and visual room. Preserve source wording unless correction or translation is requested. Each event needs a positive duration, intended line breaks, and no unintended overlap. For word highlighting, verify word onsets/ends, not just sentence start times. If only phrase timing is reliable, use phrase captions and report that limitation.

ASS supports styled captions and timed highlighting when the installed FFmpeg has a subtitle renderer; SRT is a simpler editable sidecar. Check filter/font availability and the exact rendered glyphs before choosing a style. Set the subtitle canvas to the output dimensions, resolve actual font files/fallbacks, and escape subtitle-format metacharacters. A missing font or unsupported glyph can render without causing a process failure.

Inspect captions at transitions, long lines, punctuation, and the first/last word. Match the reference's important treatment while preserving readability on the intended screen. Confirm colors, stroke/background, highlight timing, line count, and placement in the encoded video. Keep captions clear of eyes/mouth, likely platform UI, and existing titles, logos, or graphics. Review existing opening/ending overlays in full-size encoded frames; a logo being inside the crop does not prove it is unobscured. Use a stable per-cue placement override when needed; do not assume a fixed margin fits every aspect or sample.

## Framing and existing sound

Use native source pixel coordinates for local crops. A rectangle `(x,y,w,h)` must remain within the source dimensions; it is not an object detector's box or a percentage in an unrelated coordinate system. Match the crop's aspect to the output or explicitly plan padding/background. Scale after choosing the crop. Preserve useful headroom, gestures, and relevant visual context across the entire interval.

For a static talking head, a stable crop or measured punch-in can borrow shot variation. Movement may need per-interval crops or supported animated framing. Check subject extremes and crop transitions; do not fabricate camera motion from sparse frames. Complex multiwindow layouts, graphics, and tracking need explicit local implementation or a disclosed scope adjustment.

Keep the existing speech/audio unless the user asks otherwise. Apply cuts consistently to both streams; use short fades only where they preserve intelligibility and do not erase phonemes. Match visual cadence without claiming copied sound design when the reference relies on music/SFX the target lacks. Use an available asset or another supported production capability only when it serves the requested style; do not assume a generation model is connected.

## Review the encoded artifact

A useful technical pass includes `ffprobe` metadata and a full decode check such as `ffmpeg -v error -i output.mp4 -f null -`. Confirm requested duration/aspect, video and intended audio streams, and output portability. Local players commonly support H.264/yuv420p video with AAC audio; verify the requested destination's requirements rather than changing formats blindly.

Extract frames from the final encoded file at every cut/caption/crop transition and representative points during movement. Compare start/end frames and caption text to the plan. A source contact sheet cannot verify a finished render. Listen to the final encoded audio and watch picture/audio together around cuts; probe results or silence/clipping statistics alone do not prove perceptual quality.

Keep validation notes concrete: artifact inspected, measured duration/dimensions/streams, decode result, sections watched/listened to, issues corrected, and remaining limits. If the environment cannot play sound, report that constraint and supply the file for listening; do not claim audio review from successful muxing. Leave the actual video and project in a durable user-accessible output location and link them with absolute local paths.
