#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  source "$BATS_TEST_DIRNAME/test_helper/mocks.bash"
}

@test "post defaults to accounts subcommand" {
  MOCK_CURL_RESPONSE='{"data":[]}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_post > /dev/null 2>&1 || true
  [[ "$(mock_curl_args)" == *"social-accounts"* ]]
}

@test "post rejects unknown subcommand" {
  run cmd_post badcmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown subcommand 'badcmd'"* ]]
}

@test "post generate-copy requires --project" {
  run cmd_post generate-copy
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project is required"* ]]
}

@test "post generate-copy requires --clip" {
  run cmd_post generate-copy --project P1
  [ "$status" -eq 1 ]
  [[ "$output" == *"--clip is required"* ]]
}

@test "post generate-copy requires --account" {
  run cmd_post generate-copy --project P1 --clip C1
  [ "$status" -eq 1 ]
  [[ "$output" == *"--account is required"* ]]
}

@test "post publish requires --title" {
  run cmd_post publish --project P1 --clip C1 --account A1
  [ "$status" -eq 1 ]
  [[ "$output" == *"--title is required"* ]]
}

@test "post publish builds correct payload" {
  MOCK_CURL_RESPONSE='{"taskId":"T1"}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_post publish --project P1 --clip C1 --account A1 --title "My Post" > /dev/null
  [[ "$(mock_curl_body)" == *'"projectId"'* ]]
  [[ "$(mock_curl_body)" == *'"postDetail"'* ]]
  [[ "$(mock_curl_body)" == *'My Post'* ]]
}

@test "post schedule requires --at" {
  run cmd_post schedule --project P1 --clip C1 --account A1 --title "Post"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--at is required"* ]]
}

@test "post cancel requires --schedule" {
  run cmd_post cancel
  [ "$status" -eq 1 ]
  [[ "$output" == *"--schedule is required"* ]]
}

@test "post copy-status requires --job" {
  run cmd_post copy-status
  [ "$status" -eq 1 ]
  [[ "$output" == *"--job is required"* ]]
}
