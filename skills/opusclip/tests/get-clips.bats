#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  source "$BATS_TEST_DIRNAME/test_helper/mocks.bash"
}

@test "get-clips requires --project or --collection" {
  run cmd_get_clips
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project or --collection is required"* ]]
}

@test "get-clips rejects unknown flags" {
  run cmd_get_clips --bogus val
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown flag"* ]]
}

@test "get-clips with --project queries by project" {
  MOCK_CURL_RESPONSE='{"data":[]}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_get_clips --project P123 > /dev/null 2>&1 || true
  [[ "$(mock_curl_args)" == *"findByProjectId"* ]]
  [[ "$(mock_curl_args)" == *"P123"* ]]
}

@test "get-clips with --collection queries by collection" {
  MOCK_CURL_RESPONSE='{"data":[]}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_get_clips --collection COL1 > /dev/null 2>&1 || true
  [[ "$(mock_curl_args)" == *"findByCollectionId"* ]]
  [[ "$(mock_curl_args)" == *"COL1"* ]]
}
