#!/usr/bin/env bash
# Command: storyboard (requires ffmpeg)

cmd_storyboard() {
  local project_id="" clip_id="" out_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project) project_id="$2"; shift 2 ;;
      --clip)    clip_id="$2"; shift 2 ;;
      --output)  out_file="$2"; shift 2 ;;
      *) die "storyboard: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$project_id" ]] || die "storyboard: --project is required"
  [[ -n "$clip_id" ]]    || die "storyboard: --clip is required"
  need ffmpeg

  local clips_json
  clips_json=$(api_get "$API_BASE/exportable-clips?q=findByProjectId&projectId=$project_id")

  local preview_url dur_int
  preview_url=$(echo "$clips_json" | jq -r \
    --arg cid "$clip_id" \
    '.data[] | select(.curationId == $cid or .id == $cid) | .uriForPreview // empty' \
    | head -1)
  dur_int=$(echo "$clips_json" | jq -r \
    --arg cid "$clip_id" \
    '.data[] | select(.curationId == $cid or .id == $cid) | ((.durationMs // 0) / 1000 | floor)' \
    | head -1)

  [[ -n "$preview_url" ]] || die "storyboard: no preview video found for clip $clip_id"
  [[ "$dur_int" -gt 0 ]] 2>/dev/null || die "storyboard: could not determine clip duration"

  local tmp_video="/tmp/opusclip-storyboard-${clip_id}.mp4"
  echo "Downloading preview video..." >&2
  curl -sS -o "$tmp_video" "$preview_url"

  # 4 evenly spaced points (center of each quarter)
  local t1=$(( dur_int * 12 / 100 ))
  local t2=$(( dur_int * 37 / 100 ))
  local t3=$(( dur_int * 62 / 100 ))
  local t4=$(( dur_int * 87 / 100 ))

  _sb_label() {
    local s=$1 d=$2
    local pct=$(( s * 100 / d ))
    printf '%02d\\:%02d\\, %d%%' $(( s / 60 )) $(( s % 60 )) "$pct"
  }

  local l1 l2 l3 l4
  l1=$(_sb_label "$t1" "$dur_int")
  l2=$(_sb_label "$t2" "$dur_int")
  l3=$(_sb_label "$t3" "$dur_int")
  l4=$(_sb_label "$t4" "$dur_int")

  local tmp_dir="/tmp/opusclip-sb-$$"
  mkdir -p "$tmp_dir"

  _sb_frame() {
    local ts=$1 label=$2 idx=$3
    ffmpeg -y -ss "$ts" -i "$tmp_video" -frames:v 1 -update 1 -q:v 2 "$tmp_dir/raw${idx}.jpg" 2>/dev/null
    ffmpeg -y -i "$tmp_dir/raw${idx}.jpg" \
      -vf "drawtext=text='${label}':expansion=none:x=(w-tw)/2:y=h-th-10:fontsize=28:fontcolor=white:borderw=3:bordercolor=black" \
      -frames:v 1 -update 1 -q:v 2 "$tmp_dir/${idx}.jpg" 2>/dev/null
  }

  _sb_frame "$t1" "$l1" 1
  _sb_frame "$t2" "$l2" 2
  _sb_frame "$t3" "$l3" 3
  _sb_frame "$t4" "$l4" 4

  [[ -z "$out_file" ]] && out_file="/tmp/opusclip-storyboard-${clip_id}.jpg"

  ffmpeg -y \
    -i "$tmp_dir/1.jpg" -i "$tmp_dir/2.jpg" -i "$tmp_dir/3.jpg" -i "$tmp_dir/4.jpg" \
    -filter_complex "xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]" \
    -map "[out]" -frames:v 1 -update 1 -q:v 2 "$out_file" 2>/dev/null

  rm -rf "$tmp_dir"

  echo "Storyboard: $out_file" >&2

  if command -v open >/dev/null 2>&1; then
    open "$out_file"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$out_file"
  fi

  echo "{\"storyboard\": \"$out_file\"}"
}
