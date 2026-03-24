#!/usr/bin/env bash
# Command: censor (subcommands: create, status)

cmd_censor() {
  local subcmd="${1:-}"; shift 2>/dev/null || true

  case "$subcmd" in
    create)
      local project_id="" clip_id="" beep="false"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --project) project_id="$2"; shift 2 ;;
          --clip)    clip_id="$2"; shift 2 ;;
          --beep)    beep="true"; shift ;;
          *) die "censor create: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$project_id" ]] || die "censor create: --project is required"
      [[ -n "$clip_id" ]]    || die "censor create: --clip is required"
      local payload
      payload=$(jq -n --arg pid "$project_id" --arg cid "$clip_id" --argjson beep "$beep" \
        '{projectId: $pid, clipId: $cid, options: {beepSound: $beep}}')
      api_post "$API_BASE/censor-jobs" "$payload" | output
      ;;

    status)
      local job_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --job) job_id="$2"; shift 2 ;;
          *) die "censor status: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$job_id" ]] || die "censor status: --job is required"
      api_get "$API_BASE/censor-jobs/$job_id" | output
      ;;

    *)
      die "censor: unknown subcommand '$subcmd' (use create|status)"
      ;;
  esac
}
