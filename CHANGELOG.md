# Changelog

## 2.2.5 — edit-clip eval follow-ups (BUG-4 + BUG-5)

Two skill-side bugs surfaced by the v2.2.4 live eval (opus-skills-eval `evals/results/2026-05-15-v2.2.4-edit-pipeline.json`):

- **`edit-clip trim` no longer overlays trim metadata onto error responses.** Past failures (e.g. an engine `413 request entity too large`) came back as `{statusCode: 413, message, startMs, endMs, durationMs}` — looked half-successful. The overlay is now gated on `.jobId`, so error bodies pass through unmodified.
- **Multi-word `edit-clip caption-fix` now matches across caption segment boundaries.** v2.2.4's per-segment walk silently missed any find whose tokens spanned more than one segment, which is the common case (caption segments are typically 1-5 tokens, so `"Vault Dweller"` lands across seg9→seg10). v2.2.5 flattens every CaptionTrack's `textElements` into a single ordered list tagged with `(section, segment, element)` provenance, runs the sequence search on the flat list, and writes the 1:1 replacements back to their original positions. Same caveat as before: `--find` and `--replace` must have equal token counts; mismatches die with a pointer to `caption-replace` / `apply`. The `edit-clip caption-fix` success overlay is also `.jobId`-gated now (same fix as trim).

Caption-fix overlay is also `.jobId`-gated (same fix as trim).

Engine-side: the `413` itself (clip-api's 100KB Express default JSON limit on `POST /exportable-clips/:id/re-render`) is being tracked separately on clip-apps; the right fix there is a dedicated body-parser middleware scoped to the re-render route, matching the existing `AIContentBodyParserMiddleware` / `EditorHistoryContentBodyParserMiddleware` patterns.

## 2.2.4 — edit-clip / describe bugfixes from 2026-05-15 session

Three bugs surfaced while exercising the edit pipeline end-to-end:

- **`describe` now emits render-state fields**. The default output added `durationMs`, `uriForPreview`, `uriForExport`, `renderAsVideoPreview`, and `renderAsVideoFile` (the object with `.pending`). The documented polling loop (`jq -e '.renderAsVideoFile.pending == false'`) silently never resolved before because those keys weren't in the CLI output.
- **`edit-clip trim` clamps `--end` to `durationMs`**. Extending past source duration is an engine no-op (the EditingScript sectionTimeline gets clamped silently and the re-render publishes the original mp4). The CLI now clamps deterministically, surfaces `clampedEndMs` + `note` in the response, and dies early if the clamped window is degenerate.
- **`edit-clip caption-fix` supports multi-word `--find`**. Captions are stored per-word with per-token timing, so the previous regex `gsub` on each textElement never matched a multi-word string. The CLI now tokenizes `--find` / `--replace`; multi-word fixes walk consecutive textElements and replace tokens 1:1 (`"2 lonely"` → `"Two lonely"` works). Different-length rewrites die with a pointer to `caption-replace` / `apply`. Single-word `--find` keeps the existing regex `gsub` path (back-compat for in-word matches like `"haha"` → `"ha"`).

## 2.2.3 — launch-readiness pass

Findings from the 2026-05-14 full launch-readiness eval (opus-skills-eval `evals/results/2026-05-14-v2.2.2-launch-readiness.json`). All four must-fix items in one patch:

- **`storyboard`**: detect `drawtext` (libfreetype) availability at runtime. Fall back to an unlabeled 2×2 grid when missing, with a one-line stderr note pointing at `brew reinstall ffmpeg`. Removed `2>/dev/null` from every ffmpeg call — failures now surface with a clear `storyboard: ffmpeg ...` message instead of silent exit 8.
- **`need ffmpeg` install hint**: `storyboard` and local `trim` (the two ffmpeg-dependent commands) now tell users how to install ffmpeg if missing, and clarify that the command is local-only (no API alternative for storyboard; `edit-clip trim` is the server-side alternative for trim).
- **Help text**: `opusclip help` EXAMPLES now show `--durations` on the bare-submit lines, matching SKILL.md. The previous copy-paste from `help` would have hit the v2.2.1-era 500.
- **Version drift**: `.codex-plugin/plugin.json` and `.claude-plugin/marketplace.json` (×2 places) were stuck at 2.1.0 from PR #21. Bumped to 2.2.3 so registry installs report a consistent version.

## 2.2.2 — caption-replace bugfix

- Fix `edit-clip caption-replace` writing new textElements to only `.sections[0].segments[0]`, leaving every other segment + section's original textElements in place. Now collapses the CaptionTrack to a single section + single segment containing every word from the transcript, matching the doc claim "replace the whole caption track". Caught by the 2026-05-14 live eval (6 new words ended up prepended to 46 original words on a real clip).

## 2.2.1 — v2.2.0 eval follow-ups

Patches three doc gaps surfaced by the 2026-05-14 skill eval (28/28 pass — opus-skills-eval `evals/results/2026-05-14-v2.2.0.json`) and one shellcheck warning the same eval CI caught:

- SKILL.md `describe` section now shows the polling `jq` one-liner inline, not just the field name.
- SKILL.md `Common Workflows` gains an "Edit a clip, then post" recipe stitching `edit-clip * → describe poll → post publish` into one block.
- `references/editing-script.md` adds a "Which sub-verb fits which input?" decision table so "re-render with new captions" maps to the right sub-verb.
- Fix SC2155 in five `cmd_edit_clip_*` helpers — `local cid="$(clip_suffix ...)"` masked `clip_suffix`'s return value. Split into declare-then-assign so failures under `set -e` propagate.

`plugin.json` also bumped from 2.1.0 → 2.2.1 (was missed in the 2.2.0 release).

## 2.2.0 — `edit-clip` umbrella (AGE-7)

Wraps the new clip-api endpoints for server-side caption editing, trim, and any future edit op. All flows share one underlying primitive: fetch the clip's `EditingScript`, mutate it locally, POST it back to `/re-render`. Same shape the web editor uses on Save — no parallel schema, no per-op endpoint.

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
- `SKILL.md` is byte-identical to the 1.x eval-tuned baseline (19/19 from #12).
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
- docs: improve skill based on eval results (15/19 → targeting 19/19) (#12)
