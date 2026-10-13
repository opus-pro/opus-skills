# Native Production and Verification

Use the chosen local renderer's supported features. The examples describe timing and media invariants rather than prescribing a renderer or an editing template.

## Connect OpusClip MCP

Video understanding needs the OpusClip MCP server at `https://mcp.opus.pro/mcp`, or another OpusClip server URL the user was given, such as a staging environment. The OpusClip connector in the claude.ai directory does not include `opusclip_analyze_reference_media` or `opusclip_create_media_generation_job`; if it is the only OpusClip server connected, ask the user to add this one too. Call `opusclip_whoami` to confirm who is signed in, which organization is selected and whether the account has API access.

When it is missing, give the user the commands for their host and wait for them to finish:

```bash
# Claude Code: add the server, then run /mcp in Claude Code and authenticate OpusClip
claude mcp add --transport http --scope user opusclip https://mcp.opus.pro/mcp

# Codex: add the server, then sign in
codex mcp add opusclip --url https://mcp.opus.pro/mcp
codex mcp login opusclip
```

Sign-in uses OAuth in the browser, where the user also chooses an organization; an OpusClip API key for the clipping CLI does not authenticate this connection. A newly added server may appear only after the agent session restarts. If `opusclip_whoami` reports no API access, tell the user that understanding needs a plan with API access and continue locally. Never ask the user for tokens.

## Video understanding call

When the user chooses deep understanding, discover `opusclip_analyze_reference_media` on the connected OpusClip MCP. Read the exposed input schema, build your prompt from the [template](reference-analysis.md#understanding-prompt) and call it directly; there is no model-catalog discovery, quote or price-confirmation step. Tool discovery is still necessary: a documented tool is not proof of runtime availability. Do not substitute `opusclip_analyze_video`; it returns reframing boxes, not media understanding.

If authentication is required or expired, immediately tell the user which configured connector needs sign-in. Use the host's supported authentication flow: in Claude Code, open `/mcp` and authenticate that connector; in Codex CLI, use `codex mcp login <configured-connector-name>`; in a host-managed connector, use its connection settings. Surface a login link if the host provides one. Do not ask for tokens or treat missing tools, insufficient scopes, account access denials or network failures as proof that the user is logged out. For an explicit scope denial, guide the user to reauthorize the same connector with the required access.

After successful authentication, rediscover the tools and retry the original operation. Preserve any existing `jobId` and idempotency key: retrieve an existing receipt before attempting another submission. If understanding is still unavailable, report the exact missing capability or returned error, continue from the local scan, and disclose that sound and music were not analyzed.

Supply `prompt`, `mediaType`, locally measured `durationSeconds`, a stable `idempotencyKey`, and exactly one `uploadId` or `mediaUrl`. For local or linked video, prepare an MP4 as in [reference analysis](reference-analysis.md#get-the-reference-as-an-mp4), upload it with the normal `opusclip_create_upload_link` resumable upload and pass its completed upload ID. Do not pass a filesystem path or arbitrary storage URI. A `mediaUrl` must be a direct HTTPS link to the media file itself; web and social page URLs are not resolved, and the upstream HTTP-fetch limit is 15 MiB. Never expose private footage publicly as an access workaround. Trim references longer than the current 300-second per-call limit locally before upload. Check the exposed schema for supported sampling and response-length settings.

Reuse a completed understanding result when it still answers the creative question. Read [`analysis.json`](reference-analysis.md#persist-the-analysis) before any new call, and poll a saved unfinished `jobId` instead of submitting again. There is no content cache: a new key on the same media is a new charge. Analyze additional sections or the user's footage only when the user's choice covered them; each is a separate charge. The idempotency key is a unique stable string of 8–128 characters for this exact call; reuse it only for an identical retry. Changed media or prompt needs a new key. Normal MCP billing and client approval apply; do not introduce a skill budget or a confirmation step beyond the user's choice in the what-to-copy round.

Read `result.text`, the durable `jobId` and actual `chargedCredits`. Verify approximate timing claims with local frames/audio. Slow calls can return a queued or running receipt before the original execution finishes; wait `retryAfterSeconds`, then read `opusclip_get_reference_analysis({jobId})`. The getter only reads the original receipt and never runs inference or changes billing. Keep polling while the original call is queued or running; a long analysis can take several minutes. If it is still queued or running after 20 minutes, stop polling, report its job ID for operator review, and continue from the local scan, saying that sound and music were not analyzed. Terminal unresolved billing also requires operator review. If the response was lost, an identical same-key retry under normal client approval retrieves the original receipt without repeating inference or billing. `chargedCredits: null` means unresolved, never zero. `reservedCredits` is the current hold; `pendingCredits` is the full known unsettled obligation. Report actual credits only after billing settles. Do not derive a charge from token usage or account API caps. Preserve the original receipt and key when an outcome is uncertain.

## A reproducible timeline

Store each retained source interval as source start/end plus output start/end and its crop/zoom settings. Record source frame dimensions, output canvas/aspect/frame rate, subtitle styling, audio settings, and the command/script needed to render. Keep source-media paths distinct from output paths. Bundle necessary sidecars and assets, or document the original media dependency so another editor can rerender it.

Use one time unit consistently in the saved plan and label it. For normal-speed interval `[s,e)` placed at output time `o`, a source event at `t` maps to `o + (t-s)`. Output interval length is `e-s`; the next output start follows the preceding interval end. If speed changes are supported and explicitly planned, timing, audio, and captions all need the same speed transform. Do not silently time-stretch speech to force a reference duration.

Check interval order, positive lengths, source bounds, intended omissions, and total output duration before rendering. Cuts can disrupt pronouns, explanations, breaths, gestures, or mouth shapes even when timestamps are valid. Prefer semantic word/phrase boundaries grounded in the actual footage. A very short cut may encode but still be unpleasant; inspect it rather than assuming it matches a rapid reference.

In FFmpeg, trim video/audio from the same source bounds and reset their timestamps before concatenation (`trim`/`setpts` and `atrim`/`asetpts`). Keep video/audio segment counts and order identical. Normalize differing dimensions/frame rates/audio formats deliberately if combining sources. Quote file paths and filter arguments safely; do not interpolate transcript text into shell code. Use subtitle files for caption content.

## Timed captions

Prefer an existing verified word-timed transcript; otherwise use available transcription/alignment and check it against the speech. Media analysis can propose a transcript or timing, but its timestamps are hypotheses until verified. Retain original word times and create output times by mapping through the cut plan, removing words cut from the video. Check words that cross a cut instead of merely clipping their event windows.

A project-wide transcript may use original-source milliseconds while the local target is an extracted or assembled excerpt. Read the supplied extraction manifest/source-to-local mapping before declaring that transcript unmatched. Record the original source offset and any assembled cuts. Select overlapping words for each mapped source interval and place them at its local offset, then map through the new edit timeline. Do not use whole-source timestamps as local clip times. Missing offline ASR alone is not a reason to abandon supplied timed source data; verify its mapping and disclose any remaining alignment/listening uncertainty.

Group words into readable lines/phrases based on actual cadence and visual room. Preserve source wording unless correction or translation is requested. Each event needs a positive duration, intended line breaks, and no unintended overlap. For word highlighting, verify word onsets/ends, not just sentence start times. If only phrase timing is reliable, use phrase captions and report that limitation.

ASS supports styled captions and timed highlighting when the installed FFmpeg has a subtitle renderer; SRT is a simpler editable sidecar. Run the [preflight](reference-analysis.md#preflight) first and render captions with the FFmpeg it selects. A missing filter is a reason to install a capable build with the user's approval or to disclose the gap, not to change the caption look silently. Check filter/font availability and the exact rendered glyphs before choosing a style. Set the subtitle canvas to the output dimensions, resolve actual font files/fallbacks, and escape subtitle-format metacharacters. A missing font or unsupported glyph can render without causing a process failure.

Inspect captions at transitions, long lines, punctuation, and the first/last word. Match the reference's important treatment while preserving readability on the intended screen. Confirm colors, stroke/background, highlight timing, line count, and placement in the encoded video. Keep captions clear of eyes/mouth, likely platform UI, and existing titles, logos, or graphics. Review existing opening/ending overlays in full-size encoded frames; a logo being inside the crop does not prove it is unobscured. Use a stable per-cue placement override when needed; do not assume a fixed margin fits every aspect or sample.

## Framing and existing sound

Use native source pixel coordinates for local crops. A rectangle `(x,y,w,h)` must remain within the source dimensions; it is not an object detector's box or a percentage in an unrelated coordinate system. Match the crop's aspect to the output or explicitly plan padding/background. Scale after choosing the crop. Preserve useful headroom, gestures, and relevant visual context across the entire interval.

For a static talking head, a stable crop or measured punch-in can borrow shot variation. Movement may need per-interval crops or supported animated framing. Check subject extremes and crop transitions; do not fabricate camera motion from sparse frames. Complex multiwindow layouts, graphics, and tracking need explicit local implementation or a disclosed scope adjustment.

Keep the existing speech/audio unless the user asks otherwise. Apply cuts consistently to both streams; use short fades only where they preserve intelligibility and do not erase phonemes. Match visual cadence without claiming copied sound design when the reference relies on music/SFX the target lacks. Use an available asset or another supported production capability only when it serves the requested style; do not assume a generation model is connected.

## Added assets and licenses

Borrow the reference's treatment, never its material. A local copy of the reference is for analysis only. Never put its music, footage, voice, graphics, logos or font files into the output: do not rip, stem-separate, re-record or trace them, and do not look up and download a commercial track it uses. If the user owns the reference, ask for the original asset files. Otherwise follow the user's materials answer: their own files, online sources, generation, or nothing.

Search with the host's web tools, for example the CC0 filter on Openverse or Freesound, or OFL fonts from Google Fonts. The license on the asset's own page is authoritative, not a site's general "free" label. Prefer CC0, public domain, or terms that allow modification and the intended commercial or social use. Accept attribution licenses only when you can deliver the attribution, and skip non-commercial, no-derivatives, share-alike and unclear terms unless the user confirms the use fits. Some royalty-free music still triggers platform content claims, so name the track. Do not download items behind a login, payment or captcha; ask the user to fetch them. Downloads need host approval where network access is restricted, such as Codex's default sandbox. Save each download in its own directory, treat it as untrusted data and confirm it with `ffprobe`.

Generate material only when the user chose generation with a budget in the what-to-copy round, or gave one when asked for the limit, and the connected server exposes `opusclip_create_media_generation_job`. Hand each asset to `opusclip-media-generation` with its brief and spend only within that budget. Produce a long voiceover or narration in one piece, not in segments, so the voice stays consistent. Give the user a playable link to every output and sample, since you cannot listen or watch.

Match the reference's function, such as tempo, energy, timbre or typeface category, not its exact track or branded graphics. You cannot audition music: choose by the library's genre, tempo and duration tags, check its waveform for sections, and name it in the direction update so the user can swap it. Record each added asset in the project with its role, local path, source page URL or generation tool, author, license name and URL, required attribution text and date, and repeat required attributions in the delivery notes. For a generated asset, record its job ID, model and charged credits, and note that its use is subject to the user's OpusClip terms, instead of an author and license.

## Review the encoded artifact

A useful technical pass includes `ffprobe` metadata and a full decode check such as `ffmpeg -v error -i output.mp4 -f null -`. Confirm requested duration/aspect, video and intended audio streams, and output portability. Local players commonly support H.264/yuv420p video with AAC audio; verify the requested destination's requirements rather than changing formats blindly.

Extract frames from the final encoded file at every cut/caption/crop transition and representative points during movement, and verify each selected element as in [verifying the render](editing-elements.md#verifying-the-render). Compare start/end frames and caption text to the plan. A source contact sheet cannot verify a finished render. Listen to the encoded audio around cuts when the host can play it; otherwise check cuts, music changes and ducking with waveform and loudness evidence and ask the user to listen. Probe results or silence/clipping statistics alone do not prove perceptual quality.

Keep validation notes concrete: artifact inspected, measured duration/dimensions/streams, decode result, sections watched/listened to, issues corrected, and remaining limits. If the environment cannot play sound, report that constraint and supply the file for listening; do not claim audio review from successful muxing. Leave the actual video and project in a durable user-accessible output location and link them with absolute local paths.
