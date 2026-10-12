# Speech

`kind: "speech"` turns a script into a voiceover with Gemini 3.8 Flash TTS. Read the [speech generation guide](https://ai.google.dev/gemini-api/docs/speech-generation) for delivery direction and inline tags.

## Fields

| Field | Rule |
|---|---|
| `text` | Required. The exact words to speak, at most 6000 weighted characters. Each Chinese, Japanese or Korean character counts 3, so a CJK script holds about 2000 characters. |
| `voice` | One of the 30 prebuilt voices below. |
| `voiceDescription` | A voice to design, up to 1000 characters: age, tone, accent, pace. The result returns a `voiceKey`. |
| `voiceKey` | A `voiceKey` from an earlier designed-voice job, valid for about 7 days. |
| `style` | Optional delivery direction, up to 500 characters, such as "warm, unhurried" or "whispered, urgent". |

Supply exactly one of `voice`, `voiceDescription` or `voiceKey`. Speech takes no `prompt`. There is no language field: the language is detected from the text. Accent and pace come from `style`.

Inline tags such as `<laugh>`, `<sigh>` and `<short pause>` go in `text` where they should happen; the guide lists the rest. Use them sparingly. Write numbers, names and abbreviations the way they should be said.

## One call per narration

Generate a whole narration in one call so the voice, pace and room tone stay consistent; separate calls drift. Count the weighted characters before quoting. When a script is over the limit, tighten it with the user rather than splitting it into parts. A request over the limit is refused with the measured size.

The model chooses the pace. To fit a fixed slot, adjust `style` ("brisk", "relaxed"), add or remove pauses, or edit the script. After download, trim silences or retime cuts locally; avoid heavy time-stretching.

## Choose a prebuilt voice

Shortlist two or three voices from the descriptors and the user's brief. Each audition is a paid call, so quote one short line of the user's own script per voice, show the total, and run them only after approval, each with its own key. Give the user every sample's URL; they choose. Never claim you heard a sample.

| Voice | Character | Voice | Character | Voice | Character |
|---|---|---|---|---|---|
| Zephyr | bright, female | Puck | upbeat, male | Charon | informative, male |
| Kore | firm, female | Fenrir | excitable, male | Leda | youthful, female |
| Orus | firm, male | Aoede | breezy, female | Callirrhoe | easy-going, female |
| Autonoe | bright, female | Enceladus | breathy, male | Iapetus | clear, male |
| Umbriel | easy-going, male | Algieba | smooth, male | Despina | smooth, female |
| Erinome | clear, female | Algenib | gravelly, male | Rasalgethi | informative, male |
| Laomedeia | upbeat, female | Achernar | soft, female | Alnilam | firm, male |
| Schedar | even, male | Gacrux | mature, female | Pulcherrima | forward, female |
| Achird | friendly, male | Zubenelgenubi | casual, male | Vindemiatrix | gentle, female |
| Sadachbia | lively, male | Sadaltager | knowledgeable, male | Sulafat | warm, female |

## Design a voice

Use `voiceDescription` when no prebuilt voice fits. Every `voiceDescription` call designs a new voice, so do not send the description again for the full script:

1. Quote and generate a short sample, one or two sentences of the script, with `voiceDescription`.
2. Give the user the sample's URL and wait for approval. If they want changes, revise the description and repeat with a new key and a new quote.
3. Quote and generate the full script with the sample's returned `voiceKey`.

A `voiceKey` lasts about 7 days. An expired key fails with `invalid_request`; design and approve a new voice. If a `voiceKey` job fails with `provider_unavailable` and the key is about 7 days old, treat it as expired: design and approve a new voice instead of retrying. Do not describe or imitate a real, identifiable person's voice.

## Provider docs to tool fields

| In the Gemini docs | Send |
|---|---|
| transcript or input text | `text` |
| `voice` / `voice_name` in the speech config | `voice` |
| style or speech metadata in the prompt | `style` |
| a prompted (designed) voice | `voiceDescription`, then `voiceKey` |
| model, response format, sample rate, streaming | not settable; the server chooses |
| multiple speakers, voice replication | not available |

## Check the result

Read `outputs[0].mimeType` and `durationSeconds`. After download, run `ffprobe` for duration and streams, and `silencedetect` to find long gaps or a truncated ending. Compare the duration to the slot the edit needs. Ask the user to listen before you build the edit around it.
