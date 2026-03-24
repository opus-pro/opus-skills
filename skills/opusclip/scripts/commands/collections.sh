#!/usr/bin/env bash
# Command: collections (subcommands: list, create, delete, export, add-clip, remove-clip)

cmd_collections() {
  local subcmd="${1:-list}"; shift 2>/dev/null || true

  case "$subcmd" in
    list)
      local query="mine" content_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --content-id) query="findByContentId"; content_id="$2"; shift 2 ;;
          *) die "collections list: unknown flag '$1'" ;;
        esac
      done
      local url="$API_BASE/collections?q=$query"
      [[ -n "$content_id" ]] && url="$url&contentId=$content_id"
      api_get "$url" | output
      ;;

    create)
      local name=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --name) name="$2"; shift 2 ;;
          *) die "collections create: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$name" ]] || die "collections create: --name is required"
      local payload
      payload=$(jq -n --arg v "$name" '{collectionName: $v}')
      api_post "$API_BASE/collections" "$payload" | output
      ;;

    delete)
      local collection_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id) collection_id="$2"; shift 2 ;;
          *) die "collections delete: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$collection_id" ]] || die "collections delete: --id is required"
      api_delete "$API_BASE/collections/$collection_id" | output
      ;;

    export)
      local collection_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id) collection_id="$2"; shift 2 ;;
          *) die "collections export: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$collection_id" ]] || die "collections export: --id is required"
      api_post "$API_BASE/collections/$collection_id/export" "{}" | output
      ;;

    add-clip)
      local collection_id="" content_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id)         collection_id="$2"; shift 2 ;;
          --content-id) content_id="$2"; shift 2 ;;
          *) die "collections add-clip: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$collection_id" ]] || die "collections add-clip: --id is required"
      [[ -n "$content_id" ]]    || die "collections add-clip: --content-id is required"
      local payload
      payload=$(jq -n --arg cid "$collection_id" --arg xid "$content_id" \
        '{collectionId: $cid, contentId: $xid}')
      api_post "$API_BASE/collection-contents" "$payload" | output
      ;;

    remove-clip)
      local collection_id="" content_id=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id)         collection_id="$2"; shift 2 ;;
          --content-id) content_id="$2"; shift 2 ;;
          *) die "collections remove-clip: unknown flag '$1'" ;;
        esac
      done
      [[ -n "$collection_id" ]] || die "collections remove-clip: --id is required"
      [[ -n "$content_id" ]]    || die "collections remove-clip: --content-id is required"
      local payload
      payload=$(jq -n --arg cid "$collection_id" --arg xid "$content_id" \
        '{q: "findByCollectionIdAndContentId", collectionId: $cid, contentId: $xid}')
      api_post "$API_BASE/collection-contents/delete-collection-contents" "$payload" | output
      ;;

    *)
      die "collections: unknown subcommand '$subcmd' (use list|create|delete|export|add-clip|remove-clip)"
      ;;
  esac
}
