# Speech

`opusclip_create_speech_job` turns a script into a voiceover with Gemini 3.8 Flash TTS. Read the [speech generation guide](https://ai.google.dev/gemini-api/docs/speech-generation) for delivery direction and inline tags.

## Fields

| Field | Rule |
|---|---|
| `text` | Required. The exact words to speak, at most 6000 weighted characters. Each Chinese, Japanese or Korean character counts 3, so a CJK script holds about 2000 characters. |
| `voice` | Required. One of the 30 prebuilt voices below. |
| `style` | Optional persona and delivery direction, up to 500 characters, such as "husky, calm documentary narrator" or "whispered, urgent". |

Speech takes no `prompt`. There is no language field: the language is detected from the text. Accent and pace come from `style`.

Inline tags such as `<laugh>`, `<sigh>` and `<short pause>` go in `text` where they should happen; the guide lists the rest. Use them sparingly. Write numbers, names and abbreviations the way they should be said.

## One call per narration

Generate a whole narration in one call so the voice, pace and room tone stay consistent; separate calls drift. Count the weighted characters before quoting. When a script is over the limit, tighten it with the user rather than splitting it into parts. A request over the limit is refused with the measured size.

The model chooses the pace. To fit a fixed slot, adjust `style` ("brisk", "relaxed"), add or remove pauses, or edit the script. After download, trim silences or retime cuts locally; avoid heavy time-stretching.

## Choose a prebuilt voice

Pick one voice from the table below by sound and use, matched to the user's brief, and describe the persona and delivery in `style`, for example "husky, calm documentary narrator". Do not describe or imitate a real, identifiable person's voice.

When the user wants to hear a voice first, generate one short line of their own script with the chosen voice before the full script. A sample is a normal speech job: quote it and run it only after approval, with its own key. To compare two or three shortlisted voices, quote one sample per voice and show the total. Give the user every sample's URL; they choose. Never claim you heard a sample. Then generate the full narration in one call with the chosen voice.

| Voice | Gender, pitch | Sound | Good for |
|---|---|---|---|
| Achernar | female, high | soft, calm, soothing | quiet or personal storytelling |
| Achird | male, low | friendly, warm, approachable | casual walkthroughs, vlogs |
| Algenib | male, low | gravelly, grounded, hard-hitting | dramatic or intense narration |
| Algieba | male, low | smooth, relaxed, polished | corporate videos, polished explainers |
| Alnilam | male, low | firm, direct, commanding | instructions, announcements |
| Aoede | female, medium | breezy, light, relaxed | lifestyle and travel vlogs |
| Autonoe | female, medium | bright, positive, enthusiastic | promos, product feature updates |
| Callirrhoe | female, medium | easy-going, casual | friendly guides, casual vlogs |
| Charon | male, low | informative, steady | technical explainers, documentaries |
| Despina | female, medium | smooth, mellow, polished | ads, professional e-learning |
| Enceladus | male, low | breathy, intimate, soft-spoken | intimate storytelling |
| Erinome | female, medium | clear, articulate, precise | training, step-by-step instructions |
| Fenrir | male, low | excitable, high-energy | sports clips, energetic intros |
| Gacrux | female, medium | mature, authoritative | official announcements, serious presentations |
| Iapetus | male, low | clear, crisp | help videos, onboarding walkthroughs |
| Kore | female, medium | firm, direct, authoritative | news reports, official messages |
| Laomedeia | female, high | upbeat, energetic | sales pitches, social media marketing |
| Leda | female, high | youthful, vibrant | pop culture, gaming |
| Orus | male, low | firm, serious, no-nonsense | reports, safety readouts |
| Puck | male, low | upbeat, cheerful, rich | podcasts, reviews, ads |
| Pulcherrima | neutral, medium | forward, confident, direct | sales, direct calls to action |
| Rasalgethi | male, medium | informative, measured | history lectures, audiobooks |
| Sadachbia | male, low | lively, animated | daily digests, podcasts |
| Sadaltager | male, medium | knowledgeable, steady | science explainers, deep dives |
| Schedar | male, low | even, balanced | neutral scripts, documentation readouts |
| Sulafat | female, medium | warm, inviting, comforting | onboarding, warm welcomes |
| Umbriel | male, low | easy-going, laid-back | reviews, casual explainers |
| Vindemiatrix | female, medium | gentle, calming | kids content, meditation |
| Zephyr | female, high | bright, positive | showreels, product announcements |
| Zubenelgenubi | male, low | casual, conversational | startup updates, casual pitches |

## Provider docs to tool fields

| In the Gemini docs | Send |
|---|---|
| transcript or input text | `text` |
| `voice` / `voice_name` in the speech config | `voice` |
| style or speech metadata in the prompt | `style` |
| model, response format, sample rate, streaming | not settable; the server chooses |
| multiple speakers, designed (prompted) voices, voice replication | not available |

## Check the result

Read `outputs[0].mimeType` and `durationSeconds`. After download, run `ffprobe` for duration and streams, and `silencedetect` to find long gaps or a truncated ending. Compare the duration to the slot the edit needs. Ask the user to listen before you build the edit around it.
