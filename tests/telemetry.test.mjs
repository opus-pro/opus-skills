// Run with: node --test
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const SCRIPT = fileURLToPath(
  new URL("../skills/opusclip/skills/copy-video-style/scripts/telemetry.mjs", import.meta.url),
);

const tempHome = () => mkdtempSync(join(tmpdir(), "opusclip-telemetry-"));

// A clean environment with its own home, so agent markers, CI and opt-outs
// from the shell running the tests do not leak in.
function run(home, args, env = {}) {
  return spawnSync(process.execPath, [SCRIPT, ...args, "--dry-run"], {
    encoding: "utf8",
    env: { PATH: process.env.PATH, HOME: home, USERPROFILE: home, ...env },
  });
}

function event(home, args, env) {
  const result = run(home, args, env);
  assert.equal(result.status, 0);
  return JSON.parse(result.stdout);
}

test("a full run sends five anonymous events that share its run ID", () => {
  const home = tempHome();
  const agent = { CLAUDECODE: "1" };
  const started = run(home, ["run_started", "--preflight", "ok", "--missing-tool", "none", "--reference", "url"], agent);
  assert.equal(started.status, 0);
  assert.match(started.stderr, /OPUSCLIP_NO_TELEMETRY=1/, "the first event prints the notice");
  const first = JSON.parse(started.stdout);
  const run_id = first.properties.run_id;
  const id = ["--run", run_id];
  const step = (args) => event(home, [args[0], ...id, ...args.slice(1)], agent);

  const plan = step(["plan_confirmed", "--elements", "captions,pacing,captions,sparkles", "--understanding", "--budget", "50"]);
  const render = step(["render_started", "--attempt", "1", "--renderer", "ffmpeg"]);
  const rendered = run(home, ["render_finished", ...id, "--attempt", "1", "--renderer", "ffmpeg", "--outcome", "ok"], agent);
  assert.equal(rendered.stderr, "", "the notice prints only once");
  const finished = JSON.parse(rendered.stdout);
  const delivered = step([
    "delivered",
    "--revisions",
    "1",
    "--duration",
    "42.5",
    "--aspect",
    "1080x1920",
    "--generation",
    "--analysis-task",
    "mcp_media_abc123",
  ]);

  const { anonymousId } = JSON.parse(readFileSync(join(home, ".opusclip", "telemetry.json"), "utf8"));
  const events = [first, plan, render, finished, delivered];
  assert.deepEqual(
    events.map((e) => e.event),
    [
      "copy_video.run_started",
      "copy_video.plan_confirmed",
      "copy_video.render_started",
      "copy_video.render_finished",
      "copy_video.delivered",
    ],
  );
  for (const { properties } of events) {
    assert.equal(properties.run_id, run_id);
    assert.equal(properties.distinct_id, `$device:${anonymousId}`);
    assert.equal(properties.$device_id, anonymousId);
    assert.match(properties.$insert_id, /^[a-f0-9]{32}$/);
    assert.equal(properties.$user_id, undefined);
    assert.equal(properties.agent_runtime, "claude_code");
    assert.equal(properties.skill, "copy-video-style");
    assert.equal(properties.source, "skill");
    assert.equal(properties.opus_lab_app, "copy-video");
    assert.equal(properties.app_env, "prod");
  }
  assert.equal(new Set(events.map((e) => e.properties.$insert_id)).size, 5);

  assert.deepEqual(
    pick(first.properties, ["preflight_ok", "missing_tool", "has_reference", "reference_kind"]),
    { preflight_ok: true, missing_tool: "none", has_reference: true, reference_kind: "url" },
  );
  assert.deepEqual(pick(plan.properties, ["elements", "paid_understanding", "generation_budget"]), {
    elements: ["captions", "pacing", "other"],
    paid_understanding: true,
    generation_budget: 50,
  });
  assert.deepEqual(pick(render.properties, ["attempt", "renderer"]), { attempt: 1, renderer: "ffmpeg" });
  assert.deepEqual(pick(finished.properties, ["attempt", "renderer", "outcome", "render_seconds_bucket"]), {
    attempt: 1,
    renderer: "ffmpeg",
    outcome: "ok",
    render_seconds_bucket: "0-10s",
  });
  assert.deepEqual(
    pick(delivered.properties, ["revisions", "output_duration_bucket", "aspect", "used_generation", "analysis_task_id"]),
    {
      revisions: 1,
      output_duration_bucket: "30-60s",
      aspect: "9:16",
      used_generation: true,
      analysis_task_id: "mcp_media_abc123",
    },
  );
});

test("values outside the allowed sets never reach an event", () => {
  const home = tempHome();
  const started = event(home, ["run_started", "--missing-tool", join(home, "bin", "ffmpeg"), "--reference", "a.mp4"]);
  const delivered = event(home, [
    "delivered",
    "--run",
    join(home, "run"),
    "--aspect",
    "7:3",
    "--analysis-task",
    join(home, "reference.mp4"),
  ]);

  assert.equal(started.properties.missing_tool, "other");
  assert.equal(started.properties.has_reference, false);
  assert.equal(started.properties.reference_kind, undefined);
  assert.match(delivered.properties.run_id, /^[a-f0-9]{16}$/);
  assert.equal(delivered.properties.aspect, "other");
  assert.equal(delivered.properties.analysis_task_id, undefined);
  assert.ok(!JSON.stringify([started, delivered]).includes(home));
});

test("opt-outs, CI and development send and store nothing", () => {
  for (const env of [
    { OPUSCLIP_NO_TELEMETRY: "1" },
    { DO_NOT_TRACK: "1" },
    { CI: "true" },
    { CI: "1" },
    { NODE_ENV: "development" },
  ]) {
    const home = tempHome();
    const result = run(home, ["run_started", "--preflight", "ok"], env);
    assert.equal(result.status, 0);
    assert.equal(result.stdout, "", JSON.stringify(env));
    assert.equal(existsSync(join(home, ".opusclip")), false);
  }

  const home = tempHome();
  assert.match(run(home, ["disable"]).stdout, /off/);
  const result = run(home, ["run_started", "--preflight", "ok"]);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, "");
  assert.match(run(home, ["status"]).stdout, /are off/);
});

test("bad input still exits 0 without an error", () => {
  const home = tempHome();
  for (const args of [[], ["unknown"], ["render_finished", "--outcome"], ["plan_confirmed", "--budget", "lots"]]) {
    const result = run(home, args);
    assert.equal(result.status, 0);
    assert.equal(result.stderr.includes("Error"), false);
  }
});

function pick(object, keys) {
  return Object.fromEntries(keys.map((key) => [key, object[key]]));
}
