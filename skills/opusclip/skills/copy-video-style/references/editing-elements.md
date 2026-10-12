# Editing Elements

One checklist serves four steps. The local scan looks for all of it. The what-to-copy question offers only what the reference actually uses. Deep understanding, when the user chooses it, describes the chosen elements in detail. The review verifies each selected element in the encoded output. For each element, record whether the reference uses it, where, and how you confirmed it.

Evidence: **C** `scdet` cut list (and `mafd` runs), **S** contact sheet or full-size frame, **B** native-frame burst, **A** sound picture or loudness/silence measurement, **M** deep understanding result. M is a hypothesis until local evidence agrees. Without M, describe sound by measured behavior only, such as "music bed with a drop near 0:20", never by genre, instruments or voice tone. Commands are in [reference analysis](reference-analysis.md#scan-locally).

## Structure and pacing

- Opening hook, first 1-3 s: strongest line first, text hook, pattern interrupt, sound hit. B, M.
- Ending: call to action, end card, loop back to the opening, hard stop. B, M.
- Cut rhythm: median and shortest shot, fastest stretch, cuts on phrase ends, beats or actions. C, A.
- Jump cuts: pauses and breaths removed from a talking head, alternating framing to hide them. C, B.
- J- and L-cuts: the next shot's sound starts early, or sound carries over the cut. B, A, M.
- Speed: ramps, slow motion, freeze frames, reversals. B.

## Transitions

Hard cut, match cut, whip pan, zoom in or out, flash or dip to white or black, dissolve, glitch or RGB split, light leak, wipe, slide or push, shape or mask reveal, spin. Record each kind's length in frames and the sound that accompanies it. B; `scdet` alone misses dissolves and slow zooms.

## Framing and camera

- Aspect and safe zones: 9:16, 1:1 or 16:9; subject and captions clear of platform UI. S.
- Punch-ins and digital zooms: amount (for example 100% to 115%), the words or beats they land on, hard or eased. B.
- Push-ins, Ken Burns on stills, handheld or added shake. B.
- Subject placement and reframing; split screen, picture-in-picture, stacked layouts. S.
- B-roll and screen-recording cutaways: frequency, length, whether speech continues under them. S, C.

## Captions and on-screen text

- Mode: word-by-word, phrase or sentence; words per line; line count. B, M.
- Type: style (bold sans, serif, handwritten), weight, case, size relative to frame height. S at full size.
- Color: base, keyword highlight, stroke, shadow, background box, emoji. S at full size.
- Position: fixed, per shot, or avoiding the face. S.
- Animation: pop or scale-in, bounce, slide, typewriter, karaoke fill, per-word color change; entrance length in frames. B.
- Titles, lower thirds, chapter cards, numbered lists, progress bars. S, B.

## Graphics and overlays

Stickers and emoji, arrows, circles and underlines, screenshots or UI cards, meme inserts, logos and watermarks, borders and frames, grain, vignette, light leaks. S, B.

## Color and look

Contrast, saturation, warmth, skin tone, black level, grain, sharpening, grade changes between sections, flash frames. S.

## Sound

- Music: genre and instruments, sections, builds and drops, whether cuts land on beats; a tempo from M is an estimate. A, M.
- Sound effects: whooshes on transitions, pops on captions, risers, hits, clicks, and the visual event each one accompanies. A, M, B.
- Ducking: music level under speech versus without speech. A.
- Voice: on-camera or voiceover, pace, pauses kept or trimmed. A, M.
- Loudness: integrated loudness and loudness range. A.

## Asking what to copy

Ask after the local scan and before any paid call, so every option is something you observed. Write in the user's language. Open with one line of measured facts and 4-6 timecoded bullets on what defines the reference, for example:

> This reference (0:35, 9:16, 19 cuts, about 1.8 s per shot) is defined by:
> - Hook: punch-in with a 3-word title in the first 1.5 s
> - Captions: white all-caps, 2-3 words, pop-in, yellow keyword
> - Transitions: whip pans at section changes (0:08, 0:19)
> - Sound: music bed under speech, sharp transients on transitions, a loud drop at 0:20

Then ask, in one round:

- **What to copy** (multi-select). Offer only elements the reference uses, each named concretely with a time or short description. Put recommended elements first: those that fit this footage and the user's goal. When an element does not fit, say why in its description, for example "needs a second camera angle you don't have". Combine closely related details into one option. List elements the user already chose as kept instead of asking again. When an element needs something the user must approve, such as installing `ffmpeg-full` for styled captions, say so in its description so that choosing it gives consent.
- **Deep understanding** (single choice): run OpusClip video understanding on the reference for a few credits, or continue with the local scan only. Recommend it when sound, music, voice or pacing matter to the chosen style, and say why: you cannot listen, so without it sound and music are copied from measurements alone. If the footage's speech or actions also need it, offer that as a separate option and say that a second call on the footage costs a few more credits.
- **Materials** (single choice), only when an offered element needs music, sound effects, B-roll, fonts or overlays the footage lacks. Name the gaps and offer: use files the user will send; search online for free-to-use replacements (CC0, public domain or a license that covers this use; each source and license recorded, nothing taken from the reference); generate them with OpusClip up to a credit budget; or leave them out. Offer generation only when the connected server exposes `opusclip_create_media_generation_job`, and only for the assets its `kind` accepts: `speech` and `music`, and `video` when the tool's schema lists it. Name those assets and state the budget in the option itself, for example "Generate the music bed and voiceover with OpusClip, up to 50 credits". When generation covers only part of the gap, such as music but not sound effects, pair it in the same option with search or the user's files for the rest.

Before the round, draft each asset you would generate as an `opusclip-media-generation` request and quote it for free: send it with `maxCredits: 0` and a new `idempotencyKey`, record the key and the returned `estimatedCredits` in `generation.json`, and offer a budget of 50 credits, or the sum of the quotes when that is higher, so a retake or a short video clip fits. For speech, quote the script you plan to use; a changed script is a new request with a new quote. A quote creates and charges nothing. If an asset cannot be quoted, leave it out of the generation option and say why. The budget the user picks, or a different limit typed as free text, is the approval for the listed generations within that total; no further yes is needed for them. Record it as `sessionTotalCredits` in `generation.json`. The total covers only assets for elements the user selected: drop a deselected element's asset and its quote from the list and the total. If the limit is below the sum, generate the listed assets that fit, in the order listed, say which were left out, and do not ask again; never pass `maxCredits` above the remaining limit. A limit above the sum leaves room for retakes the user asks for.

Skip the round when the run cannot take a reply, such as `codex exec`, `claude -p`, a scheduled job, or a request that says not to ask. Apply the default below, keep working, and list the assumptions in the direction update.

Host tools:

- Claude Code: send the round in one `AskUserQuestion` call. It takes up to four questions with 2-4 options each and headers of 12 characters or fewer, and adds a free-text "Other". Split the elements across one or two `multiSelect: true` questions (for example Picture, Text+sound), then Analysis and, when needed, Materials. Without a materials gap, a third element question fits. Put the generation budget in the Materials options rather than adding a fifth question. The four materials options fill that question, so add no separate retake option: keep the label short, such as "Generate: 12 credits (Recommended)", and put the assets and the hint in its description, such as "Music bed and voiceover with OpusClip. For a different credit limit, type a number in Other." End recommended labels with "(Recommended)".
- Codex and other hosts: Codex's `request_user_input` is single-choice and usually available only in Plan mode, so ask the round as one plain-text message and end the turn:

> What should I copy? Reply with numbers and letters, like "1 2 A C".
> 1. Fast cuts: hard cuts on phrase ends, about 1.8 s per shot (recommended)
> 2. Captions: white all-caps, 2-3 words, pop-in, yellow keyword (recommended)
> 3. Whip transitions at section changes (0:08, 0:19)
> 4. Music bed and hits on transitions
> Reply "all" to copy every numbered element.
>
> I can't hear audio. Should OpusClip analyze the reference's sound and pacing first? It usually costs a few credits.
> A. Yes, run OpusClip video understanding (recommended: this style leans on music and hits)
> B. No, use the free frame and loudness scan (sound copied from measurements only)
>
> Your footage has no music or sound effects. Where should they come from?
> C. Files you'll send
> D. Search online for CC0 or other free-to-use tracks; I'll log each source and license
> E. Generate a music bed with OpusClip, up to 50 credits, and search for CC0 sound effects. For a different credit limit, reply like "E, 20 credits".
> F. Leave them out

Include the generation option only when the connected server exposes `opusclip_create_media_generation_job`, with the quoted credits stated. Treat free text and partial answers as direction, and apply the materials answer only to selected elements. If the reply does not answer the understanding question, do not run it; continue from the local scan and say that sound and music were not analyzed. If the user says "you decide", or nobody can answer (a non-interactive run), use the recommended elements, skip deep understanding unless the request already asked for it, do not search for, download or generate assets, and state these assumptions in the direction update. Without an explicit budget, never run paid generation. Do not ask a second round; afterwards, ask only about blockers such as sign-in, network approval, a failed download, a missing `yt-dlp`, the files the user chose to send, the user's reaction to the first test output before the rest of a generation batch, or a paid generation that returns `needs_approval`, would exceed the approved budget, or is not on the approved list. Without a reply, never install anything; disclose any caption treatment the installed FFmpeg cannot render.

## Verifying the render

Repeat the reference's evidence method on the encoded output. Rerun `scdet` and compare shot-length statistics. Burst the same kinds of moments, such as the first 3 seconds, each transition type, caption entrances, punch-ins and the ending, and view each reference and output burst side by side. Rerun the loudness and silence measurements and compare the music level under speech. Mark each selected element as matched, adapted (say how) or not reproduced (say why), and confirm that declined elements did not slip in.
