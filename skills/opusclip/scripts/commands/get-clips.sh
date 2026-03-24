#!/usr/bin/env bash
# Command: get-clips (alias: list)

cmd_get_clips() {
  local project_id="" collection_id="" summary="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)    project_id="$2"; shift 2 ;;
      --collection) collection_id="$2"; shift 2 ;;
      --summary)    summary="true"; shift ;;
      *) die "get-clips: unknown flag '$1'" ;;
    esac
  done

  local url
  if [[ -n "$project_id" ]]; then
    url="$API_BASE/exportable-clips?q=findByProjectId&projectId=$project_id"
  elif [[ -n "$collection_id" ]]; then
    url="$API_BASE/exportable-clips?q=findByCollectionId&collectionId=$collection_id"
  else
    die "get-clips: --project or --collection is required"
  fi

  local filter='[.data[] | {
    id: .id,
    rank: .rank,
    score: .score,
    title: .title,
    description: .description,
    hashtags: .hashtags,
    duration_sec: ((.durationMs // 0) / 1000 | round),
    is_bonus: .isBonusClip,
    preview_url: .uriForPreview,
    export_url: .uriForExport,
    thumbnail_url: .uriForThumbnail
  }]'

  if [[ "$summary" == "true" ]]; then
    filter='[.data[] | {
      id: .id,
      rank: .rank,
      score: .score,
      title: .title,
      description: .description,
      hashtags: .hashtags,
      duration_sec: ((.durationMs // 0) / 1000 | round),
      hook_score: .judgeResult.hookScore,
      coherence_score: .judgeResult.coherenceScore,
      connection_score: .judgeResult.connectionScore,
      trend_score: .judgeResult.trendScore
    }]'
  fi

  api_get "$url" | jq "$filter"
}
