#!/usr/bin/env bash
# Command: share-project (alias: share)

cmd_share_project() {
  local project_id="" visibility="PUBLIC"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)    project_id="$2"; shift 2 ;;
      --visibility) visibility="$2"; shift 2 ;;
      *) die "share-project: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$project_id" ]] || die "share-project: --project is required"

  local payload
  payload=$(jq -n --arg v "$visibility" '{visibility: $v}')

  api_post "$API_BASE/clip-projects/$project_id/update-visibility" "$payload" | output
}
