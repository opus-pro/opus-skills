# Billing

Speech, music and video have a fixed price per request; a video's price is its duration times a per-second rate for its resolution. The server quotes it before any work, holds that many credits when the job is admitted, charges the same amount on success and releases the hold on a definite failure; an uncertain job keeps its hold for review. There is no separate quote tool and no surprise overage, but every take, sample and retry with a new key is a new charge.

## Quote, approve, run

1. Pick a new `idempotencyKey` for the request, 8-128 characters, such as `<project>-<asset>-<take>-<short random or timestamp>`. Write it to `generation.json` before calling, and reuse it only from that record. Keys belong to the organization and outlive the session.
2. Call `opusclip_create_media_generation_job` with the full request and `maxCredits: 0`. On a new key, the result has `status: "needs_approval"`, `estimatedCredits`, `model` and `priceVersion`; nothing is created, held or charged. If the key already belongs to a job, the call returns that job's receipt instead, with no new charge. If the key belongs to a different request, it is refused with `idempotency_conflict`.
3. Tell the user what you will generate, with which model, and the exact credit cost, in one line. Wait for an explicit yes. Silence, "sounds good" about the creative plan, or a yes to an earlier request is not approval of this cost; an approved session total is, for the requests listed with it (see below). When the run cannot take a reply, or the user says "you decide", quote only: generate nothing, report each quote, and stop.
4. Call again with the identical request, the same key and `maxCredits` equal to this request's quoted `estimatedCredits`, never more than the remaining session total. `maxCredits` is not part of the request identity, so the quote and the paid call share the key.
5. If the paid call still returns `needs_approval`, the price changed: show the new estimate and ask again, even within a session total.

Change anything else, such as the text, voice, prompt, duration or resolution, and it is a new request: use a new key, quote it and get a new yes, unless it is a listed asset whose new quote fits the remaining session total.

## Session total and batches

When the user plans several generations, such as a voiceover, a music bed and three shots, ask for a session total; if the user already named a budget, that is the session total, so do not ask again. Quote every planned request, show the list and its sum, and get one yes for the list and the total, which may leave room for a retake. A copy-video-style materials answer that named the assets and the budget is that yes. That yes approves each listed request within the total, so do not ask again for each call. A changed request for a listed asset, made because the user asked for it, such as a revision after their review of the test output or a retake they requested, or fitted to the edit before the asset's first run, needs a new key and a new quote, and runs without a new yes only while that quote fits the remaining total. A retake or revision you start yourself needs its own yes. An asset that is not on the list needs its own quote and yes, even when it fits the total.

Keep a running sum: count `chargedCredits` once a job has settled and `estimatedCredits` for jobs that are queued, running or unsettled. Stop before a call would take the sum past the total, and ask before raising it. Before sending calls in parallel, add the whole batch to the running sum first; if it does not fit, tell the user how many fit and ask.

Make one test output first, such as one shot or a short speech sample, and get the user's reaction before running the rest. Never loop paid calls, regenerate "until it sounds right", or retry a creative result without the user's approval of the extra cost.

## Retries and recovery

- No receipt came back, for example after a timeout or lost connection: repeat the identical call with the same key. It returns the original job and never charges twice. A `failed` or `submission_unknown` receipt arrives as a tool error but is still a receipt; only a result without a `jobId` means no receipt came back.
- A receipt came back with `queued` or `running`: poll `opusclip_get_media_generation_job` with its `jobId` and `waitSeconds: 20`. Never call the create tool to check status. After 20 minutes (45 for video), stop polling, give the user the `jobId` and its held credits, and do not resubmit.
- A job is uncertain (`submission_unknown`) or its credits are pending review: do not resubmit with a new key. Give the user the `jobId`.
- A job failed: follow the action the getter's description gives for its `errorCode`. A retry after a fix uses a new key, a new quote and a new yes, unless it is a listed asset whose quote fits the remaining session total.

| `errorCode` | What to do |
|---|---|
| `credit_admission_rejected` | Tell the user they lack credits. After they add credits, use a new key. |
| `content_policy` | Rewrite the text or prompt; for video, use a different `firstFrameUrl` (`seedance-2.5` refuses frames that show a real person's face, `hailuo-3` accepts them). Then quote it with a new key. |
| `invalid_request` | Fix the inputs, for example design a new voice if a `voiceKey` expired, then use a new key. |
| `provider_unavailable`, `dispatch_failed`, `output_storage_failed` | Nothing was charged. Retry later with a new key and a new quote, after the user agrees, or without asking for a listed asset whose new quote fits the remaining session total. |
| `submission_unknown`, `credit_reservation_pending`, `admission_incomplete` | Credits may be held for review. Do not resubmit; give the user the `jobId`. |

## Refusals

These come back as a tool error with no receipt and no `jobId`. Nothing was created or charged. Do not retry them in a loop.

| Message starts with | What to do |
|---|---|
| `idempotency_conflict` | The key belongs to a different request. Repeat the original request exactly, or use a new key and quote again. |
| `generation_unavailable` | Generation is switched off for now. Tell the user. Existing jobs can still be read. |
| `model_unavailable` | This kind or model is not available right now; the message names only the kind, even when one video model is unavailable. Tell the user and continue without it; for `hailuo-3`, see [video](video.md) for using `seedance-2.5` instead. |
| `An API-enabled OpusClip account is required` | Explain that generation needs a plan with API access; see `opusclip_whoami`. |
| `text is ...` (over the character limit) | Shorten the script with the user. Do not split it. |
| `speech requires ...` / `music requires ...` | Fix the fields. |
| `video requires prompt, model and durationSeconds and takes no speech fields` | Add the missing fields and drop any speech fields. |
| `durationSeconds must be 5-15 for hailuo-3 or 4-30 for seedance-2.5` | Change the duration, or switch to the model that allows it. |
| `resolution must be 768p or 2k for hailuo-3, or 480p or 720p for seedance-2.5` | Use a resolution the chosen model offers. |
| `aspectRatio cannot be combined with firstFrameUrl; the video takes the frame shape` | Drop `aspectRatio`. |
| `lastFrameUrl is supported only by hailuo-3, together with firstFrameUrl` | Use `hailuo-3` with a `firstFrameUrl`, or drop `lastFrameUrl`. |
| `generateAudio is supported only by seedance-2.5` | Drop `generateAudio`, or use `seedance-2.5`. |
| `hailuo-3 accepts a prompt of at most 7000 characters` | Shorten the prompt. |
| `Supply a public HTTPS image URL without credentials` | Use a public HTTPS frame URL the user already hosts. |
| `Media generation job not found in this organization` | Check the `jobId`. Jobs belong to the organization the connection signed in with. |

## Receipt fields

| Field | Meaning |
|---|---|
| `jobId` | Use it with the getter and in your records. |
| `status` | `queued`, `running`, `succeeded`, `failed` or `submission_unknown`. |
| `estimatedCredits` | The price this job was admitted at. |
| `reservedCredits` | Credits currently held for it. |
| `chargedCredits` | The final charge, or `null` until billing settles. `null` is not zero. |
| `priceVersion` | The price list the estimate came from. |
| `outputs[]` | `url`, `expiresAt`, `mimeType`, and when present `durationSeconds`, `voiceKey` (designed speech) or `lyrics` (music). |
| `errorCode` | Why a job failed or is uncertain. |
| `retryAfterSeconds` | Present while `queued` or `running`; read the job again after it, or poll with `waitSeconds: 20`. |

## generation.json

Write a record before each call and update it when a receipt returns and when the job ends:

```json
{
  "sessionTotalCredits": 40,
  "jobs": [
    {
      "kind": "speech",
      "model": "gemini-3.8-flash-tts",
      "params": { "voiceDescription": "warm, unhurried, mid-30s", "textFile": "generated/promo-vo-take1-k3f9.txt" },
      "idempotencyKey": "promo-vo-take1-k3f9",
      "jobId": "...",
      "estimatedCredits": 2,
      "chargedCredits": 2,
      "status": "succeeded",
      "voiceKey": "...",
      "voiceKeyCreatedAt": "2026-10-12T09:30:00Z",
      "localFile": "generated/promo-vo-take1-k3f9.wav"
    }
  ]
}
```

Credit values are illustrative; use the quoted `estimatedCredits`. Save each job's exact text as `generated/<idempotencyKey>.txt` and reference that file, not a shared script that may change later. For designed speech, record the returned `voiceKey` and when it was created so a later session can reuse it within about 7 days. Do not store signed URLs as the durable record; read the job again for a fresh one.
