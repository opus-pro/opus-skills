#!/usr/bin/env bash
# Command: upload

cmd_upload() {
  local file="" title="" template_id="" model="" genre="" keywords="" custom_prompt=""
  local aspect="portrait" skip_curate="false" source_lang="" webhook_url=""
  local clip_durations="" range_start="" range_end="" remove_filler="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)            file="$2"; shift 2 ;;
      --title)           title="$2"; shift 2 ;;
      --template)        template_id="$2"; shift 2 ;;
      --model)           model="$2"; shift 2 ;;
      --genre)           genre="$2"; shift 2 ;;
      --keywords)        keywords="$2"; shift 2 ;;
      --prompt)          custom_prompt="$2"; shift 2 ;;
      --aspect)          aspect="$2"; shift 2 ;;
      --skip-curate)     skip_curate="true"; shift ;;
      --lang)            source_lang="$2"; shift 2 ;;
      --webhook)         webhook_url="$2"; shift 2 ;;
      --durations)       clip_durations="$2"; shift 2 ;;
      --range-start)     range_start="$2"; shift 2 ;;
      --range-end)       range_end="$2"; shift 2 ;;
      --remove-filler)   remove_filler="true"; shift ;;
      *) die "upload: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$file" ]] || die "upload: --file is required"
  [[ -f "$file" ]] || die "upload: file '$file' not found"

  echo "Step 1/4: Requesting upload link..." >&2
  local upload_resp
  upload_resp=$(api_post "$API_BASE/upload-links" '{"video":{"usecase":"LocalUpload"}}')

  local gcs_url upload_id
  gcs_url=$(echo "$upload_resp" | jq -r '.url')
  upload_id=$(echo "$upload_resp" | jq -r '.uploadId')

  [[ "$gcs_url" != "null" ]] || die "upload: failed to get upload URL. Response: $upload_resp"

  echo "Step 2/4: Initiating resumable upload session..." >&2
  local session_url
  session_url=$(curl -sS -D - -o /dev/null -X POST "$gcs_url" \
    -H "x-goog-resumable: start" \
    -H "Content-Length: 0" | grep -i "^location:" | tr -d '\r' | sed 's/^[Ll]ocation: //')

  [[ -n "$session_url" ]] || die "upload: failed to get resumable session URL"

  echo "Step 3/4: Uploading video file..." >&2
  curl -sS -X PUT "$session_url" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$file" > /dev/null

  echo "Step 4/4: Creating clip project..." >&2
  local args=(--url "$upload_id")
  [[ -n "$title" ]]          && args+=(--title "$title")
  [[ -n "$template_id" ]]    && args+=(--template "$template_id")
  [[ -n "$model" ]]          && args+=(--model "$model")
  [[ -n "$genre" ]]          && args+=(--genre "$genre")
  [[ -n "$keywords" ]]       && args+=(--keywords "$keywords")
  [[ -n "$custom_prompt" ]]  && args+=(--prompt "$custom_prompt")
  [[ "$aspect" != "portrait" ]] && args+=(--aspect "$aspect")
  [[ "$skip_curate" == "true" ]] && args+=(--skip-curate)
  [[ -n "$source_lang" ]]    && args+=(--lang "$source_lang")
  [[ -n "$webhook_url" ]]    && args+=(--webhook "$webhook_url")
  [[ -n "$clip_durations" ]] && args+=(--durations "$clip_durations")
  [[ -n "$range_start" ]]    && args+=(--range-start "$range_start")
  [[ -n "$range_end" ]]      && args+=(--range-end "$range_end")
  [[ "$remove_filler" == "true" ]] && args+=(--remove-filler)

  cmd_create_project "${args[@]}"
}
