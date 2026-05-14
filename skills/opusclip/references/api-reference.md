# OpusClip API Reference

Base URL: `https://api.opus.pro/api`
Auth: `Authorization: Bearer <API_KEY>` on all requests.
Rate limit: 30 req/min. Max video: 10h / 30GB. Max concurrent: 50 projects.

## Table of Contents

- [Create Project](#create-project)
- [Get Clips](#get-clips)
- [Share Project](#share-project)
- [Brand Templates](#brand-templates)
- [Upload Video](#upload-video)
- [Collections](#collections)
- [Collection Contents](#collection-contents)
- [Censor Jobs](#censor-jobs)
- [Social Posting](#social-posting)

---

## Create Project

**POST** `/clip-projects`

Create clips from a video URL (YouTube, Vimeo, Google Drive, Zoom, Rumble, Twitch, Facebook, LinkedIn, X, Dropbox, Riverside, Loom, Frame.io, StreamYard, or direct S3 MP4).

Request body:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `videoUrl` | string | yes | Source video URL |
| `brandTemplateId` | string | no | Template ID (default: account default) |
| `uploadedVideoAttr` | object | no | `{title: string}` |
| `curationPref` | object | no | See below |
| `renderPref` | object | no | See below |
| `importPreference` | object | no | `{sourceLang: string}` (ISO code, auto-detected if omitted) |
| `conclusionActions` | array | no | `[{type: "WEBHOOK"\|"EMAIL", url?, email?, notifyFailure?}]` |

**curationPref:**

| Field | Type | Description |
|-------|------|-------------|
| `model` | string | `ClipBasic` (talking-head) or `ClipAnything` (diverse content) |
| `clipDurations` | [number, number][] | Duration ranges as `[[min, max], ...]` in seconds, e.g. `[[0, 30], [0, 60]]` |
| `genre` | string | Video genre hint |
| `topicKeywords` | string[] | Keywords (ClipBasic only) |
| `customPrompt` | string | Custom prompt (ClipAnything only) |
| `range` | object | `{startSec: number, endSec: number}` |
| `skipCurate` | boolean | Skip AI curation, process original only |

**renderPref:**

| Field | Type | Description |
|-------|------|-------------|
| `layoutAspectRatio` | string | `portrait` \| `landscape` \| `square` |
| `quickstartConfig.enableRemoveFillerWords` | boolean | Remove filler words |

---

## Get Clips

**GET** `/exportable-clips`

Query params:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | yes | `findByProjectId` or `findByCollectionId` |
| `projectId` | string | conditional | Required when q=findByProjectId |
| `collectionId` | string | conditional | Required when q=findByCollectionId |

Additional headers: `x-opus-org-id: <ORG_ID>` (optional).

Returns a list of clips with IDs and export URIs.

---

## Share Project

**POST** `/clip-projects/{projectId}/update-visibility`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `visibility` | string | yes | `PUBLIC` or `DEFAULT` |

---

## Brand Templates

**GET** `/brand-templates?q=mine`

Returns list of templates with `brandTemplateId` and name.

---

## Upload Video

4-step process for uploading local files:

### Step 1: Get Upload Link

**POST** `/upload-links`

```json
{"video": {"usecase": "LocalUpload"}}
```

Response: `{url, uploadId, dnsUrl, useAmount, totalAmount}`

### Step 2: Initiate Resumable Session

**POST** to the `url` from step 1, with header `x-goog-resumable: start` and `Content-Length: 0`. Extract `Location` header from response.

### Step 3: Upload File

**PUT** to the `Location` URL with `Content-Type: application/octet-stream` and binary file data.

### Step 4: Create Project

**POST** `/clip-projects` using the `uploadId` from step 1 as the `videoUrl`.

---

## Collections

### List Collections

**GET** `/collections?q=mine`
**GET** `/collections?q=findByContentId&contentId=CONTENT_ID`

Response: `{data: {list: [{collectionId, collectionName, createdAt, updatedAt}], total, next, limit}}`

### Create Collection

**POST** `/collections`

```json
{"collectionName": "My Collection"}
```

Response: `{data: {collectionId, collectionName, createdAt, updatedAt}}`

### Delete Collection

**DELETE** `/collections/{collectionId}`

Clips are preserved; only the collection is removed.

Response: `{data: "collectionId"}`

### Export Collection

**POST** `/collections/{collectionId}/export`

Body: `{}`

Response: `{data: {contentList: [{contentId, uriForExport}]}}`

---

## Collection Contents

Content IDs use the format `{projectId}.{curationId}`.

### Add Clip to Collection

**POST** `/collection-contents`

```json
{"collectionId": "...", "contentId": "PROJECT_ID.CLIP_ID"}
```

### Remove Clip from Collection

**POST** `/collection-contents/delete-collection-contents`

```json
{
  "q": "findByCollectionIdAndContentId",
  "collectionId": "...",
  "contentId": "PROJECT_ID.CLIP_ID"
}
```

---

## Censor Jobs

### Create Censor Job

**POST** `/censor-jobs`

```json
{
  "projectId": "...",
  "clipId": "...",
  "options": {"beepSound": false}
}
```

Response (201): `{jobId, message}`

### Get Censor Job Status

**GET** `/censor-jobs/{jobId}`

Response: `{status: "QUEUED"|"PROCESSING"|"CONCLUDED"|"FAILED"|"UNKNOWN", error?: string}`

---

## Social Posting

Distribute clips to connected social channels: YouTube, TikTok Business, Facebook Page, Instagram Business, LinkedIn, X (Twitter).

Rate limits: `GET /social-accounts` 10 req/s · `POST /social-copy-jobs` 1 req/s · `GET /social-copy-jobs/{jobId}` 10 req/s · `POST /post-tasks` 1 req/s · `POST /publish-schedules` 1 req/s · `DELETE /publish-schedules/{scheduleId}` 1 req/s.

Each post to X consumes 1 credit.

### Get Social Accounts

**GET** `/social-accounts?q=mine`

Response:

```json
{
  "data": [
    {
      "postAccountId": "string",
      "subAccountId": "string",
      "platform": "YOUTUBE|TIKTOK_BUSINESS|FACEBOOK_PAGE|INSTAGRAM_BUSINESS|LINKEDIN|TWITTER",
      "extUserId": "string",
      "extUserName": "string",
      "extUserPictureLink": "string",
      "extUserProfileLink": "string"
    }
  ]
}
```

### Create Social Copy Job

**POST** `/social-copy-jobs`

Generate platform-optimized post copy for a clip.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | yes | Project ID |
| `clipId` | string | yes | Clip ID |
| `postAccountId` | string | yes | Target social account ID |
| `subAccountId` | string | no | Sub-account for Facebook/Instagram/LinkedIn |
| `prompt` | string | no | Custom tone/style instruction |
| `forceRegenerate` | boolean | no | Bypass cached results |

Response (201): `{data: {jobId: "string"}}`

### Get Social Copy Result

**GET** `/social-copy-jobs/{jobId}`

Poll for generated copy. Status values: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

Returns generated copy text when status is `COMPLETED`.

### Publish Instantly

**POST** `/post-tasks`

Publish a clip immediately to a connected social account.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | yes | Project ID |
| `clipId` | string | yes | Clip ID |
| `postAccountId` | string | yes | Target account ID |
| `subAccountId` | string | no | Sub-account for Facebook/Instagram/LinkedIn |
| `postDetail` | object | yes | Post metadata (see below) |

**postDetail:**

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Post title |
| `mediaType` | string | Platform-dependent media type |
| `custom` | object | `{description?: string, privacy?: "public"\|"private"\|"unlisted"}` |

### Schedule a Post

**POST** `/publish-schedules`

Schedule a clip for future publishing.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | yes | Project ID |
| `clipId` | string | yes | Clip ID |
| `postAccountId` | string | yes | Target account ID |
| `subAccountId` | string | no | Sub-account for Facebook/Instagram/LinkedIn |
| `publishAt` | string | yes | Future time in ISO 8601 UTC |
| `postDetail` | object | yes | Same as Publish Instantly |

Response (201): `{data: {scheduleId: "string"}}`

### Cancel a Scheduled Post

**DELETE** `/publish-schedules/{scheduleId}`

Cancel a scheduled post before it publishes.
