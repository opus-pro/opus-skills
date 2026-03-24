#!/usr/bin/env bash
# Command: post (subcommands: accounts, generate-copy, copy-status, publish, schedule, cancel)

cmd_post() {
  local subcmd="${1:-accounts}"; shift 2>/dev/null || true

  case "$subcmd" in
    accounts)
      local filter='[.data[] | {
        postAccountId: .postAccountId,
        subAccountId: .subAccountId,
        platform: .platform,
        name: .extUserName,
        profile_url: .extUserProfileLink
      }]'
      api_get "$API_BASE/social-accounts?q=mine" | jq "$filter"
      ;;

    generate-copy)
      local project_id="" clip_id="" account_id="" sub_account="" prompt="" force="false"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --project)     project_id="$2"; shift 2 ;;
          --clip)        clip_id="$2"; shift 2 ;;
          --account)     account_id="$2"; shift 2 ;;
          --sub-account) sub_account="$2"; shift 2 ;;
          --prompt)      prompt="$2"; shift 2 ;;
          --force)       force="true"; shift ;;
          *) die "post generate-copy: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$project_id" ]] || die "post generate-copy: --project is required"
      [[ -n "$clip_id" ]]    || die "post generate-copy: --clip is required"
      [[ -n "$account_id" ]] || die "post generate-copy: --account is required"

      local payload
      payload=$(jq -n \
        --arg pid "$project_id" --arg cid "$clip_id" --arg aid "$account_id" \
        '{projectId: $pid, clipId: $cid, postAccountId: $aid}')
      [[ -n "$sub_account" ]] && payload=$(echo "$payload" | jq --arg v "$sub_account" '. + {subAccountId: $v}')
      [[ -n "$prompt" ]]      && payload=$(echo "$payload" | jq --arg v "$prompt" '. + {prompt: $v}')
      [[ "$force" == "true" ]] && payload=$(echo "$payload" | jq '. + {forceRegenerate: true}')

      api_post "$API_BASE/social-copy-jobs" "$payload" | output
      ;;

    copy-status)
      local job_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --job) job_id="$2"; shift 2 ;;
          *) die "post copy-status: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$job_id" ]] || die "post copy-status: --job is required"
      api_get "$API_BASE/social-copy-jobs/$job_id" | output
      ;;

    publish)
      local project_id="" clip_id="" account_id="" sub_account=""
      local title="" description="" privacy="" media_type=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --project)     project_id="$2"; shift 2 ;;
          --clip)        clip_id="$2"; shift 2 ;;
          --account)     account_id="$2"; shift 2 ;;
          --sub-account) sub_account="$2"; shift 2 ;;
          --title)       title="$2"; shift 2 ;;
          --description) description="$2"; shift 2 ;;
          --privacy)     privacy="$2"; shift 2 ;;
          --media-type)  media_type="$2"; shift 2 ;;
          *) die "post publish: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$project_id" ]] || die "post publish: --project is required"
      [[ -n "$clip_id" ]]    || die "post publish: --clip is required"
      [[ -n "$account_id" ]] || die "post publish: --account is required"
      [[ -n "$title" ]]      || die "post publish: --title is required"

      local post_detail
      post_detail=$(jq -n --arg t "$title" '{title: $t}')
      [[ -n "$media_type" ]] && post_detail=$(echo "$post_detail" | jq --arg v "$media_type" '. + {mediaType: $v}')
      local custom="{}"
      [[ -n "$description" ]] && custom=$(echo "$custom" | jq --arg v "$description" '. + {description: $v}')
      [[ -n "$privacy" ]]     && custom=$(echo "$custom" | jq --arg v "$privacy" '. + {privacy: $v}')
      [[ "$custom" != "{}" ]] && post_detail=$(echo "$post_detail" | jq --argjson c "$custom" '. + {custom: $c}')

      local payload
      payload=$(jq -n \
        --arg pid "$project_id" --arg cid "$clip_id" --arg aid "$account_id" \
        --argjson pd "$post_detail" \
        '{projectId: $pid, clipId: $cid, postAccountId: $aid, postDetail: $pd}')
      [[ -n "$sub_account" ]] && payload=$(echo "$payload" | jq --arg v "$sub_account" '. + {subAccountId: $v}')

      api_post "$API_BASE/post-tasks" "$payload" | output
      ;;

    schedule)
      local project_id="" clip_id="" account_id="" sub_account="" publish_at=""
      local title="" description="" privacy="" media_type=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --project)     project_id="$2"; shift 2 ;;
          --clip)        clip_id="$2"; shift 2 ;;
          --account)     account_id="$2"; shift 2 ;;
          --sub-account) sub_account="$2"; shift 2 ;;
          --at)          publish_at="$2"; shift 2 ;;
          --title)       title="$2"; shift 2 ;;
          --description) description="$2"; shift 2 ;;
          --privacy)     privacy="$2"; shift 2 ;;
          --media-type)  media_type="$2"; shift 2 ;;
          *) die "post schedule: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$project_id" ]] || die "post schedule: --project is required"
      [[ -n "$clip_id" ]]    || die "post schedule: --clip is required"
      [[ -n "$account_id" ]] || die "post schedule: --account is required"
      [[ -n "$title" ]]      || die "post schedule: --title is required"
      [[ -n "$publish_at" ]] || die "post schedule: --at is required (ISO 8601 UTC, e.g. 2026-03-25T14:00:00Z)"

      local post_detail
      post_detail=$(jq -n --arg t "$title" '{title: $t}')
      [[ -n "$media_type" ]] && post_detail=$(echo "$post_detail" | jq --arg v "$media_type" '. + {mediaType: $v}')
      local custom="{}"
      [[ -n "$description" ]] && custom=$(echo "$custom" | jq --arg v "$description" '. + {description: $v}')
      [[ -n "$privacy" ]]     && custom=$(echo "$custom" | jq --arg v "$privacy" '. + {privacy: $v}')
      [[ "$custom" != "{}" ]] && post_detail=$(echo "$post_detail" | jq --argjson c "$custom" '. + {custom: $c}')

      local payload
      payload=$(jq -n \
        --arg pid "$project_id" --arg cid "$clip_id" --arg aid "$account_id" \
        --arg at "$publish_at" --argjson pd "$post_detail" \
        '{projectId: $pid, clipId: $cid, postAccountId: $aid, publishAt: $at, postDetail: $pd}')
      [[ -n "$sub_account" ]] && payload=$(echo "$payload" | jq --arg v "$sub_account" '. + {subAccountId: $v}')

      api_post "$API_BASE/publish-schedules" "$payload" | output
      ;;

    cancel)
      local schedule_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --schedule) schedule_id="$2"; shift 2 ;;
          *) die "post cancel: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$schedule_id" ]] || die "post cancel: --schedule is required"
      api_delete "$API_BASE/publish-schedules/$schedule_id" | output
      ;;

    *)
      die "post: unknown subcommand '$subcmd' (use accounts|generate-copy|copy-status|publish|schedule|cancel)"
      ;;
  esac
}
