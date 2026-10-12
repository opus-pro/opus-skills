# Music

`kind: "music"` generates a track with Lyria 3.5. Read the [music generation guide](https://ai.google.dev/gemini-api/docs/music-generation) and the [Lyria 3 Pro prompting guide](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-lyria-3-pro) (an earlier model; its prompt structure still applies).

## The prompt is the only control

Music takes `prompt` (up to 8000 characters) and no speech fields. There are no separate fields for tempo, key, length, seed or vocals, so put everything in the prompt:

- Genre and mood, such as "warm lo-fi hip hop, relaxed and optimistic".
- Instruments and texture, such as "dusty drums, Rhodes chords, soft bass, vinyl crackle".
- Tempo and key, such as "85 BPM, D minor".
- Structure and timing, such as "4-bar intro, build at 0:12, full groove from 0:16, clean ending at 0:45".
- Target length, such as "about 45 seconds".
- Vocals: write "instrumental only, no vocals", or give your own lyrics marked with `[Verse]` and `[Chorus]`. Lyrics are sung in their own language.

When the track sits under speech, ask for space for the voice: "sparse arrangement, no lead melody in the vocal range, steady energy".

Results differ between identical requests, and each take is a new paid call with a new key and a new quote.

## Rules

Never name a real artist, band, song or album, and never ask for a soundalike. Describe the function instead: tempo, energy, instrumentation, era or mood. Never use copyrighted lyrics. When copying a video's style, match what its music does for the edit, never the track itself, and never feed the reference's audio or lyrics into the prompt.

Output carries an inaudible watermark identifying it as AI-generated.

## Provider docs to tool fields

| In the Lyria docs | Send |
|---|---|
| prompt or input text | `prompt` |
| `[Verse]`, `[Chorus]`, `[Bridge]` lyric tags, section timestamps | inside `prompt` |
| tempo, key, duration, "instrumental" | inside `prompt` |
| model, response format | not settable; the server chooses |
| image inputs, seed, negative prompt, sample count | not available; describe exclusions in `prompt` |

## Check the result

Read `outputs[0].mimeType`, `durationSeconds` and `lyrics`. Compare `lyrics` with the request: an instrumental request should return no sung lyrics, and supplied lyrics should match what you sent. After download, run `ffprobe` for duration and streams. Measure loudness and look at the waveform to find the intro, build, drops and ending before you time the edit to it. Trim, loop or fade locally to fit; do not pay for a rerun to change length by a few seconds. Ask the user to listen.
