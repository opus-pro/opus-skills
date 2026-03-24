#!/usr/bin/env bash
# Command: trim (requires ffmpeg)

cmd_trim() {
  local project_id="" clip_id="" start_sec="" end_sec="" out_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project) project_id="$2"; shift 2 ;;
      --clip)    clip_id="$2"; shift 2 ;;
      --start)   start_sec="$2"; shift 2 ;;
      --end)     end_sec="$2"; shift 2 ;;
      --output)  out_file="$2"; shift 2 ;;
      *) die "trim: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$project_id" ]] || die "trim: --project is required"
  [[ -n "$clip_id" ]]    || die "trim: --clip is required"
  [[ -n "$start_sec" ]]  || die "trim: --start is required"
  [[ -n "$end_sec" ]]    || die "trim: --end is required"
  need ffmpeg

  local clips_json
  clips_json=$(api_get "$API_BASE/exportable-clips?q=findByProjectId&projectId=$project_id")

  local preview_url
  preview_url=$(echo "$clips_json" | jq -r \
    --arg cid "$clip_id" \
    '.data[] | select(.curationId == $cid or .id == $cid) | .uriForPreview // empty' \
    | head -1)

  [[ -n "$preview_url" ]] || die "trim: no preview video found for clip $clip_id"

  local tmp_video="/tmp/opusclip-trim-${clip_id}.mp4"
  echo "Downloading preview video..." >&2
  curl -sS -o "$tmp_video" "$preview_url"

  [[ -z "$out_file" ]] && out_file="/tmp/opusclip-trimmed-${clip_id}.mp4"
  ffmpeg -y -i "$tmp_video" -ss "$start_sec" -to "$end_sec" -c copy "$out_file" 2>/dev/null

  echo "Trimmed: $out_file" >&2
  echo "{\"output\": \"$out_file\", \"start\": $start_sec, \"end\": $end_sec}"
}
