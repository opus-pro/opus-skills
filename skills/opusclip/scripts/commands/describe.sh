#!/usr/bin/env bash
# Command: describe

cmd_describe() {
  local project_id="" clip_id="" show_transcript="false" show_layout="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)    project_id="$2"; shift 2 ;;
      --clip)       clip_id="$2"; shift 2 ;;
      --transcript) show_transcript="true"; shift ;;
      --layout)     show_layout="true"; shift ;;
      *) die "describe: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$project_id" ]] || die "describe: --project is required"
  [[ -n "$clip_id" ]]    || die "describe: --clip is required"

  local clips_json
  clips_json=$(api_get "$API_BASE/exportable-clips?q=findByProjectId&projectId=$project_id")

  if [[ "$show_transcript" == "true" ]]; then
    echo "$clips_json" | jq --arg cid "$clip_id" \
      '.data[] | select(.curationId == $cid or .id == $cid) | {
        id: .id,
        title: .title,
        transcript: .text
      }'
  fi

  if [[ "$show_layout" == "true" ]]; then
    echo "$clips_json" | jq --arg cid "$clip_id" \
      '.data[] | select(.curationId == $cid or .id == $cid) | {
        id: .id,
        layout: .renderPref.layoutType,
        aspect: .renderPref.layoutAspectRatio
      }'
  fi

  # Default: show both
  if [[ "$show_transcript" == "false" && "$show_layout" == "false" ]]; then
    echo "$clips_json" | jq --arg cid "$clip_id" \
      '.data[] | select(.curationId == $cid or .id == $cid) | {
        id: .id,
        title: .title,
        description: .description,
        transcript: .text,
        hashtags: .hashtags,
        keywords: .clipKeywords,
        duration_sec: ((.durationMs // 0) / 1000 | round),
        score: .score
      }'
  fi
}
