#!/usr/bin/env bash
# Command: create-project (alias: submit)

cmd_create_project() {
  local video_url="" template_id="" model="" genre="" keywords="" custom_prompt=""
  local aspect="portrait" skip_curate="false" source_lang="" webhook_url=""
  local clip_durations="" range_start="" range_end="" title=""
  local remove_filler="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url)             video_url="$2"; shift 2 ;;
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
      --title)           title="$2"; shift 2 ;;
      --remove-filler)   remove_filler="true"; shift ;;
      *) die "create-project: unknown flag '$1'" ;;
    esac
  done

  [[ -n "$video_url" ]] || die "create-project: --url is required"

  local payload
  payload=$(jq -n --arg videoUrl "$video_url" '{videoUrl: $videoUrl}')

  if [[ -n "$template_id" ]]; then
    payload=$(echo "$payload" | jq --arg v "$template_id" '. + {brandTemplateId: $v}')
  fi
  if [[ -n "$title" ]]; then
    payload=$(echo "$payload" | jq --arg v "$title" '. + {uploadedVideoAttr: {title: $v}}')
  fi

  # curationPref
  local curation="{}"
  [[ -n "$model" ]]          && curation=$(echo "$curation" | jq --arg v "$model" '. + {model: $v}')
  [[ -n "$genre" ]]          && curation=$(echo "$curation" | jq --arg v "$genre" '. + {genre: $v}')
  [[ -n "$keywords" ]]       && curation=$(echo "$curation" | jq --arg v "$keywords" '. + {topicKeywords: ($v | split(","))}')
  [[ -n "$custom_prompt" ]]  && curation=$(echo "$curation" | jq --arg v "$custom_prompt" '. + {customPrompt: $v}')
  [[ -n "$clip_durations" ]] && curation=$(echo "$curation" | jq --arg v "$clip_durations" '. + {clipDurations: ($v | split(",") | map(tonumber))}')
  [[ "$skip_curate" == "true" ]] && curation=$(echo "$curation" | jq '. + {skipCurate: true}')
  if [[ -n "$range_start" || -n "$range_end" ]]; then
    local range="{}"
    [[ -n "$range_start" ]] && range=$(echo "$range" | jq --arg v "$range_start" '. + {startSec: ($v | tonumber)}')
    [[ -n "$range_end" ]]   && range=$(echo "$range" | jq --arg v "$range_end" '. + {endSec: ($v | tonumber)}')
    curation=$(echo "$curation" | jq --argjson r "$range" '. + {range: $r}')
  fi
  [[ "$curation" != "{}" ]] && payload=$(echo "$payload" | jq --argjson c "$curation" '. + {curationPref: $c}')

  # renderPref
  local render="{}"
  render=$(echo "$render" | jq --arg v "$aspect" '. + {layoutAspectRatio: $v}')
  [[ "$remove_filler" == "true" ]] && render=$(echo "$render" | jq '. + {quickstartConfig: {enableRemoveFillerWords: true}}')
  payload=$(echo "$payload" | jq --argjson r "$render" '. + {renderPref: $r}')

  # importPreference
  [[ -n "$source_lang" ]] && payload=$(echo "$payload" | jq --arg v "$source_lang" '. + {importPreference: {sourceLang: $v}}')

  # conclusionActions
  [[ -n "$webhook_url" ]] && payload=$(echo "$payload" | jq --arg v "$webhook_url" '. + {conclusionActions: [{type: "WEBHOOK", url: $v}]}')

  api_post "$API_BASE/clip-projects" "$payload" | output
}
