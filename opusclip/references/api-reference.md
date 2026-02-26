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
| `clipDurations` | number[] | Target durations in seconds |
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
