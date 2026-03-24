#!/usr/bin/env bash
# Command: preview

cmd_preview() {
  local project_id="" collection_id="" out_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)    project_id="$2"; shift 2 ;;
      --collection) collection_id="$2"; shift 2 ;;
      --output)     out_file="$2"; shift 2 ;;
      *) die "preview: unknown flag '$1'" ;;
    esac
  done

  local url
  if [[ -n "$project_id" ]]; then
    url="$API_BASE/exportable-clips?q=findByProjectId&projectId=$project_id"
  elif [[ -n "$collection_id" ]]; then
    url="$API_BASE/exportable-clips?q=findByCollectionId&collectionId=$collection_id"
  else
    die "preview: --project or --collection is required"
  fi

  local clips_json
  clips_json=$(api_get "$url")

  local clip_count
  clip_count=$(echo "$clips_json" | jq '.data | length')

  if [[ "$clip_count" -eq 0 ]]; then
    die "preview: no clips found (project may still be processing)"
  fi

  local project_title
  project_title=$(echo "$clips_json" | jq -r '.data[0].title // "OpusClip Preview"')

  # Build clip cards HTML
  local cards=""
  cards=$(echo "$clips_json" | jq -r '.data | sort_by(-.score) | to_entries[] | @json' | while IFS= read -r entry; do
    local idx score title desc tags duration preview_url
    local hook_s coherence_s connection_s trend_s

    idx=$(echo "$entry" | jq -r '.key')
    score=$(echo "$entry" | jq -r '.value.score // "—"')
    title=$(echo "$entry" | jq -r '.value.title // "Untitled Clip"')
    desc=$(echo "$entry" | jq -r '.value.description // ""')
    tags=$(echo "$entry" | jq -r '.value.hashtags // ""')
    duration=$(echo "$entry" | jq -r '((.value.durationMs // 0) / 1000 | floor) as $s | "\($s / 60 | floor):\(($s % 60) | tostring | if length < 2 then "0" + . else . end)"')
    preview_url=$(echo "$entry" | jq -r '.value.uriForPreview // ""')
    hook_s=$(echo "$entry" | jq -r '.value.judgeResult.hookScore // "—"')
    coherence_s=$(echo "$entry" | jq -r '.value.judgeResult.coherenceScore // "—"')
    connection_s=$(echo "$entry" | jq -r '.value.judgeResult.connectionScore // "—"')
    trend_s=$(echo "$entry" | jq -r '.value.judgeResult.trendScore // "—"')

    cat <<CARD
    <div class="clip">
      <video controls preload="metadata" src="$preview_url"></video>
      <div class="clip-info">
        <span class="clip-rank">#$((idx + 1))</span>
        <span class="clip-score">Score: $score</span>
        <span class="clip-duration">$duration</span>
        <div class="clip-title">$title</div>
        <div class="clip-desc">$desc</div>
        <div class="clip-tags">$tags</div>
        <div class="scores">
          <span>Hook: $hook_s</span>
          <span>Coherence: $coherence_s</span>
          <span>Connection: $connection_s</span>
          <span>Trend: $trend_s</span>
        </div>
      </div>
    </div>
CARD
  done)

  # SCRIPT_DIR is set by the main dispatcher
  local template_file="${SCRIPT_DIR}/../templates/preview.html"
  [[ -f "$template_file" ]] || die "preview: template not found at $template_file"

  local html
  html=$(cat "$template_file")
  html="${html//\{\{PROJECT_TITLE\}\}/$project_title}"
  html="${html//\{\{CLIP_COUNT\}\}/$clip_count}"
  html="${html//\{\{CLIP_CARDS\}\}/$cards}"

  if [[ -z "$out_file" ]]; then
    out_file="/tmp/opusclip-preview-${project_id:-${collection_id}}.html"
  fi

  echo "$html" > "$out_file"
  echo "Preview written to: $out_file" >&2

  if command -v open >/dev/null 2>&1; then
    open "$out_file"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$out_file"
  fi

  echo "{\"preview\": \"$out_file\", \"clips\": $clip_count}"
}
