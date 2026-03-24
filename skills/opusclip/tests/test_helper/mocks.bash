#!/usr/bin/env bash
# Mock curl for offline testing
# Captures calls to temp files and returns MOCK_CURL_RESPONSE

MOCK_DIR="${BATS_TEST_TMPDIR:-/tmp/bats-mock-$$}"
mkdir -p "$MOCK_DIR"

MOCK_CURL_RESPONSE='{"data": []}'

curl() {
  echo "$*" > "$MOCK_DIR/curl_args"
  # Capture -d body argument
  local capture_next="false"
  for arg in "$@"; do
    if [[ "$capture_next" == "true" ]]; then
      echo "$arg" > "$MOCK_DIR/curl_body"
      capture_next="false"
    fi
    [[ "$arg" == "-d" ]] && capture_next="true"
  done
  echo "$MOCK_CURL_RESPONSE"
}
export -f curl

mock_curl_args() { cat "$MOCK_DIR/curl_args" 2>/dev/null; }
mock_curl_body() { cat "$MOCK_DIR/curl_body" 2>/dev/null; }
