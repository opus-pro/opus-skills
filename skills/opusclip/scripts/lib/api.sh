#!/usr/bin/env bash
# API helpers for OpusClip CLI

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$LIB_DIR/common.sh"

# shellcheck disable=SC2034  # used by sourcing scripts
API_BASE="${OPUSCLIP_API_URL:-https://api.opus.pro/api}"

api_key() {
  [[ -n "${OPUSCLIP_API_KEY:-}" ]] || die "OPUSCLIP_API_KEY is not set. API access requires an Enterprise plan: https://www.opus.pro/pricing?utm_source=cli&utm_medium=opus"
  echo "$OPUSCLIP_API_KEY"
}

EXTRA_HEADER_FLAGS=()
if [[ -n "${OPUSCLIP_EXTRA_HEADERS:-}" ]]; then
  IFS=';' read -ra _hdr_parts <<< "$OPUSCLIP_EXTRA_HEADERS"
  for _h in "${_hdr_parts[@]}"; do
    _h="${_h#"${_h%%[![:space:]]*}"}"
    _h="${_h%"${_h##*[![:space:]]}"}"
    [[ -n "$_h" ]] && EXTRA_HEADER_FLAGS+=(-H "$_h")
  done
  unset _hdr_parts _h
fi

# POST with JSON body
api_post() {
  local url="$1"; shift
  local body="$1"; shift
  curl -sS -X POST "$url" \
    -H "Authorization: Bearer $(api_key)" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    ${EXTRA_HEADER_FLAGS[@]+"${EXTRA_HEADER_FLAGS[@]}"} \
    -d "$body" "$@"
}

# GET with query string
api_get() {
  local url="$1"; shift
  curl -sS -X GET "$url" \
    -H "Authorization: Bearer $(api_key)" \
    -H "Accept: application/json" \
    ${EXTRA_HEADER_FLAGS[@]+"${EXTRA_HEADER_FLAGS[@]}"} \
    "$@"
}

# DELETE
api_delete() {
  local url="$1"; shift
  curl -sS -X DELETE "$url" \
    -H "Authorization: Bearer $(api_key)" \
    -H "Accept: application/json" \
    ${EXTRA_HEADER_FLAGS[@]+"${EXTRA_HEADER_FLAGS[@]}"} \
    "$@"
}
