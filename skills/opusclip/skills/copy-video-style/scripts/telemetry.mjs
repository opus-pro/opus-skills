#!/usr/bin/env node
// Anonymous usage events for the copy-video-style skill, one per checkpoint:
//
//   run_started     --preflight ok|failed --missing-tool <tool|none> --reference file|url|none
//                   Prints the run ID that the later calls pass as --run.
//   plan_confirmed  --run <id> --elements <comma list> [--understanding] --budget <credits>
//   render_started  --run <id> --attempt <n> --renderer ffmpeg|hyperframes|remotion|other
//   render_finished --run <id> --attempt <n> --renderer <same> --outcome ok|failed
//   delivered       --run <id> --revisions <n> --duration <seconds> --aspect <width>:<height>
//                   [--generation] [--analysis-task <jobId>]
//   status | enable | disable
//
// --dry-run prints the event instead of sending it. Every property is an enum,
// boolean or number, plus the OpusClip understanding job ID and a random
// install ID kept in ~/.opusclip/telemetry.json: never paths, file names, URLs,
// prompts, captions or transcript text. Off when OPUSCLIP_NO_TELEMETRY or
// DO_NOT_TRACK is set, in CI, with NODE_ENV=development, or after `disable`.
// Always exits 0 and never prints errors, so a failed send cannot derail the
// agent running it.

import { createHash, randomBytes, randomUUID } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { parseArgs } from "node:util";

const SKILL_VERSION = "3.9.0";
// Opus Lab Mixpanel project. A project token is publishable: it can write
// events but not read any data.
const MIXPANEL_TOKEN = "b89ed8f179ddc82bbe521bdbc55cc65d";
// ip=0: Mixpanel does not geolocate or store the request IP.
const TRACK_URL = "https://api.mixpanel.com/track?ip=0";
const TIMEOUT_MS = 2000;

const CONFIG_DIR = join(homedir(), ".opusclip");
const CONFIG_FILE = join(CONFIG_DIR, "telemetry.json");
const NOTICE =
  "OpusClip's copy-video-style skill sends anonymous usage events (run started, plan confirmed, render started and " +
  "finished, delivered) with settings such as the chosen elements, renderer, outcome and output length bucket, never " +
  "file paths, names, prompts or media. Turn them off with OPUSCLIP_NO_TELEMETRY=1, DO_NOT_TRACK=1 or " +
  "`node scripts/telemetry.mjs disable`.";

const EVENTS = ["run_started", "plan_confirmed", "render_started", "render_finished", "delivered"];
const TOOLS = ["none", "ffmpeg", "ffprobe", "ffmpeg_subtitles", "ffmpeg_drawtext", "yt_dlp"];
const ELEMENTS = [
  "pacing",
  "transitions",
  "framing",
  "captions",
  "text_overlays",
  "graphics",
  "grading",
  "music",
  "sound_effects",
  "voiceover",
  "b_roll",
];
const RENDERERS = ["ffmpeg", "hyperframes", "remotion"];
const ASPECTS = { "9:16": 9 / 16, "16:9": 16 / 9, "1:1": 1, "4:5": 4 / 5 };

// Which coding agent ran the script, from the existence of each agent's own
// environment markers (the same ones the HyperFrames CLI uses). Values are
// never read or sent.
const AGENTS = [
  ["claude_code", (env) => "CLAUDECODE" in env || "CLAUDE_CODE_ENTRYPOINT" in env],
  ["codex", (env) => "CODEX_THREAD_ID" in env || "CODEX_CI" in env || "CODEX_SANDBOX_NETWORK_DISABLED" in env],
  ["cursor", (env) => env.TERM_PROGRAM === "cursor"],
  ["openclaw", (env) => "OPENCLAW_STATE_DIR" in env || "OPENCLAW_CONFIG_PATH" in env],
];

function off(config) {
  const { OPUSCLIP_NO_TELEMETRY, DO_NOT_TRACK, CI, NODE_ENV } = process.env;
  const set = (value) => value !== undefined && !["", "0", "false"].includes(value);
  return (
    config.enabled === false ||
    set(OPUSCLIP_NO_TELEMETRY) ||
    set(DO_NOT_TRACK) ||
    CI === "true" ||
    CI === "1" ||
    NODE_ENV === "development"
  );
}

function readConfig() {
  try {
    const config = JSON.parse(readFileSync(CONFIG_FILE, "utf8"));
    return config && typeof config === "object" && !Array.isArray(config) ? config : {};
  } catch {
    return {};
  }
}

function writeConfig(config) {
  try {
    mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 });
    writeFileSync(CONFIG_FILE, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  } catch {
    // A read-only home only costs the stable install ID and render timing.
  }
}

const oneOf = (value, allowed, fallback = "other") => (allowed.includes(value) ? value : fallback);

function count(value, min) {
  const n = Number(value);
  return typeof value === "string" && Number.isInteger(n) && n >= min ? n : min;
}

const bucket = (seconds, edges) => edges.find(([limit]) => seconds < limit)[1];

function aspectLabel(value) {
  const [width, height] = value.split(/[:x×]/i).map(Number);
  const ratio = width / height;
  const match = Object.entries(ASPECTS).find(([, known]) => Math.abs(ratio / known - 1) < 0.02);
  return match ? match[0] : "other";
}

function eventProperties(command, flags, config, runId) {
  switch (command) {
    case "run_started": {
      const reference = oneOf(flags.reference, ["file", "url", "none"]);
      return {
        preflight_ok: flags.preflight === "ok",
        ...(typeof flags["missing-tool"] === "string" ? { missing_tool: oneOf(flags["missing-tool"], TOOLS) } : {}),
        has_reference: reference === "file" || reference === "url",
        ...(reference === "file" || reference === "url" ? { reference_kind: reference } : {}),
      };
    }
    case "plan_confirmed": {
      const elements = typeof flags.elements === "string" ? flags.elements.split(",").map((e) => e.trim()) : [];
      const budget = Number(flags.budget);
      return {
        elements: [...new Set(elements.filter(Boolean).map((e) => oneOf(e, ELEMENTS)))],
        paid_understanding: flags.understanding === true,
        generation_budget: typeof flags.budget === "string" && Number.isFinite(budget) && budget > 0 ? budget : 0,
      };
    }
    case "render_started":
      return { attempt: count(flags.attempt, 1), renderer: oneOf(flags.renderer, RENDERERS) };
    case "render_finished": {
      const attempt = count(flags.attempt, 1);
      const started = config.render?.key === `${runId}:${attempt}` ? config.render.startedAt : undefined;
      return {
        attempt,
        renderer: oneOf(flags.renderer, RENDERERS),
        outcome: oneOf(flags.outcome, ["ok", "failed"], "unknown"),
        ...(typeof started === "number"
          ? {
              render_seconds_bucket: bucket((Date.now() - started) / 1000, [
                [10, "0-10s"],
                [30, "10-30s"],
                [60, "30-60s"],
                [180, "1-3m"],
                [600, "3-10m"],
                [Number.POSITIVE_INFINITY, "10m+"],
              ]),
            }
          : {}),
      };
    }
    case "delivered": {
      const seconds = typeof flags.duration === "string" ? Number(flags.duration) : Number.NaN;
      const task = flags["analysis-task"];
      return {
        revisions: count(flags.revisions, 0),
        ...(seconds > 0 && Number.isFinite(seconds)
          ? {
              output_duration_bucket: bucket(seconds, [
                [15, "0-15s"],
                [30, "15-30s"],
                [60, "30-60s"],
                [180, "1-3m"],
                [Number.POSITIVE_INFINITY, "3m+"],
              ]),
            }
          : {}),
        ...(typeof flags.aspect === "string" ? { aspect: aspectLabel(flags.aspect) } : {}),
        used_generation: flags.generation === true,
        ...(typeof task === "string" && /^[\w-]{1,64}$/.test(task) ? { analysis_task_id: task } : {}),
      };
    }
  }
}

async function main() {
  const { values: flags, positionals } = parseArgs({
    args: process.argv.slice(2),
    allowPositionals: true,
    strict: false,
    options: {
      run: { type: "string" },
      preflight: { type: "string" },
      "missing-tool": { type: "string" },
      reference: { type: "string" },
      elements: { type: "string" },
      understanding: { type: "boolean" },
      budget: { type: "string" },
      attempt: { type: "string" },
      renderer: { type: "string" },
      outcome: { type: "string" },
      revisions: { type: "string" },
      duration: { type: "string" },
      aspect: { type: "string" },
      generation: { type: "boolean" },
      "analysis-task": { type: "string" },
      "dry-run": { type: "boolean" },
    },
  });
  const command = positionals[0];
  const config = readConfig();

  if (command === "enable" || command === "disable") {
    writeConfig({ ...config, enabled: command === "enable" });
    console.log(`Anonymous usage events are ${command === "enable" ? "on" : "off"}.`);
    return;
  }
  if (command === "status") {
    console.log(`Anonymous usage events are ${off(config) ? "off" : "on"}. Settings: ${CONFIG_FILE}`);
    return;
  }
  if (!EVENTS.includes(command) || off(config)) return;

  // run_started opens a run; the later calls pass its ID back with --run.
  const runId =
    command !== "run_started" && typeof flags.run === "string" && /^[a-f0-9]{16}$/.test(flags.run)
      ? flags.run
      : randomBytes(8).toString("hex");
  const properties = eventProperties(command, flags, config, runId);

  config.anonymousId ||= randomUUID();
  const showNotice = !config.noticeShown;
  config.noticeShown = true;
  if (command === "render_started") config.render = { key: `${runId}:${properties.attempt}`, startedAt: Date.now() };
  writeConfig(config);
  if (showNotice) console.error(NOTICE);

  const repeat = properties.attempt ?? properties.revisions ?? 0;
  const event = {
    event: `copy_video.${command}`,
    properties: {
      ...properties,
      token: MIXPANEL_TOKEN,
      time: Date.now(),
      distinct_id: `$device:${config.anonymousId}`,
      $device_id: config.anonymousId,
      $insert_id: createHash("sha256").update(`${runId}:${command}:${repeat}`).digest("hex").slice(0, 32),
      run_id: runId,
      skill: "copy-video-style",
      skill_version: SKILL_VERSION,
      agent_runtime: AGENTS.find(([, detect]) => detect(process.env))?.[0],
      source: "skill",
      opus_lab_app: "copy-video",
      app_env: "prod",
    },
  };

  if (flags["dry-run"] === true) {
    console.log(JSON.stringify(event, null, 2));
    return;
  }
  if (command === "run_started") console.log(runId);
  await fetch(TRACK_URL, {
    method: "POST",
    body: new URLSearchParams({ data: JSON.stringify([event]) }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
}

main()
  .catch(() => {})
  .finally(() => {
    process.exitCode = 0;
  });
