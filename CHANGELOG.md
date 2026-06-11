# Changelog

## 3.2.0 — resource + verb command shape

The CLI adopts a **resource + verb** subcommand tree (`opusclip project create`, `opusclip clip list`, `opusclip clip edit get`), matching REST-style CLIs like `git` and `linear`. Highlights:

- `project create` unifies `submit` (remote URL) and `upload` (local `--file`) under one verb.
- `clip get` replaces `describe`; `clip edit` replaces `edit-clip`; `collection` replaces `collections`; `template list` replaces `templates`; `thumbnail create` replaces bare `thumbnail`.
- Social posting: `post create` (was `publish`), `post account list` (was `accounts`), `post copy create|get` (was `generate-copy`/`copy-status`).
- **Every legacy bare verb still works as an alias** — existing scripts and agents don't break. The resource + verb forms are now canonical in docs and tests.
- The MCP tool names are unchanged (deliberately flat); the two surfaces share one taxonomy, expressed natively per surface.

Also re-syncs `.codex-plugin/plugin.json` to the release version (it had been stuck at 2.2.7 since the 3.0.0 cutover — the exact manifest drift the build-SHA provenance scheme exists to catch).

CLI source: opus-pro/clip-apps `apps/opusclip-cli` (AGE-302); bundle BUILD_SHA `60ecb0052e`.

## 3.1.0 — `usage` command: check your API cap

Adds `opusclip usage` — the first new command since the 3.0.0 CLI rebuild. It reports how much of the org's monthly API cap is used and how close it is to the limit:

- **Capped:** `{ uncapped: false, monthly: { used, limit, remaining, reset_at }, concurrent: { used, limit } }`. The monthly numbers match the `X-RateLimit-*` headers returned on every API response, so the command can't drift from what's actually enforced.
- **Uncapped:** `{ uncapped: true }` for orgs with no API cap (some Enterprise plans).

## 2.2.7 — edit-clip is now thin transport; agent owns EditingScript construction

Three `edit-clip` sub-verbs are **removed**: `trim`, `caption-fix`, `caption-replace`. They hand-rolled `EditingScript` mutations in jq inside the CLI and drifted from the re-render API's contract — producing re-renders that silently ignored the requested edit (e.g. captions shifted to the new window but the underlying video/audio stayed pinned to the original clip). Users reported the trim case as not-actually-trimming the video; the same class of defect was latent in `caption-fix` and `caption-replace`.

The reframe: the public CLI is not the right place for that algorithm to live. `EditingScript` construction is the API's contract; the CLI should be thin transport, and the agent that's reading SKILL.md should be the one constructing the script — from worked samples that show the right shape. That's now how it works.

What stays in the CLI:

- `edit-clip get` — fetches the clip's current `EditingScript` JSON.
- `edit-clip apply --script <file>` — submits an edited script for re-render.
- `edit-clip censor [--beep]` — calls a dedicated profanity-censor endpoint; the server does the script construction here.

What moves to the agent (via `references/editing-script.md`):

- Worked before/after samples for: typo fix in captions, trim/shrink a clip to a sub-window, replace the whole caption track from a transcript file.
- An anatomy section explaining the two coordinate systems (source-media duration vs. clip-relative timeline) and how they relate. This is the part that's easy to get wrong, and reading it once is cheaper than debugging silent renders.

What happens if you invoke a removed verb: the CLI dies immediately with a one-line message pointing at the get/apply round-trip and `references/editing-script.md`. No silent failure, no charged re-render.

Out of scope: the dedicated profanity-censor endpoint is unchanged. Multi-section clips (from curated multi-clip projects) still need extra care during trim — the worked sample handles single-section clips, which is what the re-render API typically produces.

## 2.2.6 — copyright hint before submit

SKILL.md now instructs the agent to narrate the OpusClip web app's copyright disclaimer verbatim immediately before `opusclip submit` / `opusclip upload`:

> Using video you don't own may violate copyright laws. By continuing, you confirm this is your own original content.

Mirrors the copyright disclaimer shown in the OpusClip web app's submit flow. Hint, not blocker — it's narrated as a plain notice, with no hard gate on submit.

CLI script content is unchanged this release; the version bump is for the SKILL.md behavior change and to keep the plugin/marketplace manifests aligned.

## 2.2.5 — edit-clip bugfixes

Two skill-side bugs found while testing the v2.2.4 edit pipeline:

- **`edit-clip trim` no longer overlays trim metadata onto error responses.** Past failures (e.g. an engine `413 request entity too large`) came back as `{statusCode: 413, message, startMs, endMs, durationMs}` — looked half-successful. The overlay is now gated on `.jobId`, so error bodies pass through unmodified.
- **Multi-word `edit-clip caption-fix` now matches across caption segment boundaries.** v2.2.4's per-segment walk silently missed any find whose tokens spanned more than one segment, which is the common case (caption segments are typically 1-5 tokens, so `"Vault Dweller"` lands across seg9→seg10). v2.2.5 flattens every CaptionTrack's `textElements` into a single ordered list tagged with `(section, segment, element)` provenance, runs the sequence search on the flat list, and writes the 1:1 replacements back to their original positions. Same caveat as before: `--find` and `--replace` must have equal token counts; mismatches die with a pointer to `caption-replace` / `apply`. The `edit-clip caption-fix` success overlay is also `.jobId`-gated now (same fix as trim).

Caption-fix overlay is also `.jobId`-gated (same fix as trim).

## 2.2.4 — edit-clip / describe bugfixes from 2026-05-15 session

Three bugs surfaced while exercising the edit pipeline end-to-end:

- **`describe` now emits render-state fields**. The default output added `durationMs`, `uriForPreview`, `uriForExport`, `renderAsVideoPreview`, and `renderAsVideoFile` (the object with `.pending`). The documented polling loop (`jq -e '.renderAsVideoFile.pending == false'`) silently never resolved before because those keys weren't in the CLI output.
- **`edit-clip trim` clamps `--end` to `durationMs`**. Extending past source duration is an engine no-op (the EditingScript sectionTimeline gets clamped silently and the re-render publishes the original mp4). The CLI now clamps deterministically, surfaces `clampedEndMs` + `note` in the response, and dies early if the clamped window is degenerate.
- **`edit-clip caption-fix` supports multi-word `--find`**. Captions are stored per-word with per-token timing, so the previous regex `gsub` on each textElement never matched a multi-word string. The CLI now tokenizes `--find` / `--replace`; multi-word fixes walk consecutive textElements and replace tokens 1:1 (`"2 lonely"` → `"Two lonely"` works). Different-length rewrites die with a pointer to `caption-replace` / `apply`. Single-word `--find` keeps the existing regex `gsub` path (back-compat for in-word matches like `"haha"` → `"ha"`).

## 2.2.3 — launch-readiness pass

Four must-fix items from a 2026-05-14 launch-readiness pass, in one patch:

- **`storyboard`**: detect `drawtext` (libfreetype) availability at runtime. Fall back to an unlabeled 2×2 grid when missing, with a one-line stderr note pointing at `brew reinstall ffmpeg`. Removed `2>/dev/null` from every ffmpeg call — failures now surface with a clear `storyboard: ffmpeg ...` message instead of silent exit 8.
- **`need ffmpeg` install hint**: `storyboard` and local `trim` (the two ffmpeg-dependent commands) now tell users how to install ffmpeg if missing, and clarify that the command is local-only (no API alternative for storyboard; `edit-clip trim` is the server-side alternative for trim).
- **Help text**: `opusclip help` EXAMPLES now show `--durations` on the bare-submit lines, matching SKILL.md. The previous copy-paste from `help` would have hit the v2.2.1-era 500.
- **Version drift**: `.codex-plugin/plugin.json` and `.claude-plugin/marketplace.json` (×2 places) were stuck at 2.1.0 from PR #21. Bumped to 2.2.3 so registry installs report a consistent version.

## 2.2.2 — caption-replace bugfix

- Fix `edit-clip caption-replace` writing new textElements to only `.sections[0].segments[0]`, leaving every other segment + section's original textElements in place. Now collapses the CaptionTrack to a single section + single segment containing every word from the transcript, matching the doc claim "replace the whole caption track". Caught in live testing (6 new words ended up prepended to 46 original words on a real clip).

## 2.2.1 — v2.2.0 follow-ups

Patches three doc gaps found during testing (28/28 pass) and one shellcheck warning:

- SKILL.md `describe` section now shows the polling `jq` one-liner inline, not just the field name.
- SKILL.md `Common Workflows` gains an "Edit a clip, then post" recipe stitching `edit-clip * → describe poll → post publish` into one block.
- `references/editing-script.md` adds a "Which sub-verb fits which input?" decision table so "re-render with new captions" maps to the right sub-verb.
- Fix SC2155 in five `cmd_edit_clip_*` helpers — `local cid="$(clip_suffix ...)"` masked `clip_suffix`'s return value. Split into declare-then-assign so failures under `set -e` propagate.

`plugin.json` also bumped from 2.1.0 → 2.2.1 (was missed in the 2.2.0 release).

## 2.2.0 — `edit-clip` umbrella

Wraps the new server-side edit endpoints for caption editing, trim, and any future edit op. All flows share one underlying primitive: fetch the clip's `EditingScript`, mutate it locally, POST it back to `/re-render`. Same shape the web editor uses on Save — no parallel schema, no per-op endpoint.

### Added

- `opusclip edit-clip get` — fetch the clip's `EditingScript` JSON via `?include=editingScript` opt-in on the existing GET clip endpoint. Round-trip helper.
- `opusclip edit-clip apply --script file.json` — submit a fully edited `EditingScript` directly. Escape hatch for any edit the web editor supports.
- `opusclip edit-clip caption-fix --find X --replace Y` — find/replace caption text across every `TextElement`; re-renders. `--ignore-case` for case-insensitive matching. Short-circuits with `matchCount: 0` if nothing matches (no credit spend).
- `opusclip edit-clip caption-replace --transcript file.json` — replace the whole caption track from a transcript file (`{segments: [{text, startMs, endMs, words?}]}`). Per-word timings produce karaoke-style highlighting.
- `opusclip edit-clip trim --start S --end E` — server-side trim with re-render. Shrink only in v1; extending past source duration is unverified at the engine and warns. Accepts seconds (`--start`/`--end`) or milliseconds (`--start-ms`/`--end-ms`).
- `references/editing-script.md` — concrete recipes (typo fix, trim, full caption replace) showing the exact mutation paths.

### Changed (breaking)

- **`opusclip censor` moved to `opusclip edit-clip censor`.** Profanity censoring is conceptually a server-side clip edit, same as the new caption-fix / trim flows — they all mutate the editingScript and trigger a re-render. Folded under the `edit-clip` umbrella for consistency.
- **`opusclip censor status` removed.** Use `opusclip describe --project PID --clip CID` and watch `renderAsVideoFile.pending`. The CLI no longer surfaces the censor-job-specific QUEUED/PROCESSING enum, but the underlying `/api/censor-jobs/:jobId` API is unchanged at the HTTP layer.

### Notes

- All five edit sub-verbs hit `POST /re-render` (except `get`, which is a read, and `censor`, which still posts to the existing `/api/censor-jobs` controller — same engine pipeline under the hood). Beta caps apply (15h monthly cap, 4 concurrent projects, 10-credit per-project floor for Pro/Trial users).
- Existing `opusclip trim` (local ffmpeg, free, instant) is unchanged. Both verbs coexist: top-level `trim` for offline cuts of the preview mp4, `edit-clip trim` for charged server-side trim with proper caption + brand-template handling.
- Status: poll via existing `opusclip describe` — `renderAsVideoFile.pending` flips false when the new render is ready; `uriForExport` then points at the new mp4.

## 2.1.0 — Pure-skill repo

Reverts the 2.0.0 plugin-marketplace + MCP changes. Back to the pre-2.0.0 shape: one skill at `skills/opusclip/` driving the OpusClip REST API via the bundled bash CLI.

- Drop the bundled stdio MCP server (`.mcp.json`, `mcp-server.mjs`, `mcp-server/` source) — duplicated what the bash CLI already does on the same hosts.
- Drop the `plugins/opusclip/` wrapper — only existed to host MCP config at a plugin root.
- Drop `docs/install/` — README install table + SKILL.md cover everything.
- Restore `skills/opusclip/templates/preview.html`; `opusclip preview` is no longer shipped-broken.
- `SKILL.md` is byte-identical to the 1.x tuned baseline (#12).
- `OPUSCLIP_API_KEY` access now also available on the Pro plan, not just Enterprise.

## 2.0.0 — Plugin marketplace + MCP server

**Breaking — repo layout changed.** Re-install with `/plugin update opusclip@opus-skills` (Claude Code) or `codex plugin marketplace upgrade` (Codex). Skill-only `npx skills update` installs also need to be refreshed.

### Added
- **MCP server** at `mcp-server/`, bundled with esbuild into a single self-contained file at `plugins/opusclip/mcp-server.mjs` and shipped inside the plugin (no npm publish — `.mcp.json` runs `node ${CLAUDE_PLUGIN_ROOT}/mcp-server.mjs`). 20 tools mirroring the bash CLI's API surface (`submit_video`, `list_clips`, `describe_clip`, `list_brand_templates`, `share_project`, `upload_local_video`, plus 6 collection, 2 censor, and 6 social-posting tools). stdio + HTTP entrypoints in source.
- **Codex plugin manifest** at `plugins/opusclip/.codex-plugin/plugin.json` with a rich `interface` block (displayName, logo, screenshots, capabilities) for marketplace presentation.
- **Per-agent install docs** under `docs/install/` for Claude Code, Codex CLI/App, Claude.ai, Claude Cowork, and OpenClaw.

### Changed
- **Repo layout**: skill moved from `skills/opusclip/` to `plugins/opusclip/skills/opusclip/` per Claude Code's plugin auto-discovery contract. Marketplace `source` updated accordingly.
- **MCP-first dispatch** in `SKILL.md`: model is instructed to prefer MCP tools when present, fall back to the bash CLI otherwise.
- **Bash CLI** version bumped to 2.0.0.

### Removed
- `opusclip preview` bash command (template file was deleted in a prior PR and the command was broken). MCP server does not expose a preview tool either — it's a UI helper, not an API call. Use `list_clips` to get preview URLs and embed them yourself.

## 1.3.0 — *2026-04-29*
- chore: bump version to 1.3.0

## 1.2.0 — *2026-04-26*
- fix: strip project prefix from composite clip IDs (#15)
- fix: `clipDurations` format — use `[[min,max]]` ranges, not flat array (#14)
- chore: bump version to 1.2.0 (#13)

## 1.1.0 — *2026-04-24*
- docs: improve skill based on test results (#12)
