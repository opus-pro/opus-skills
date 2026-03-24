#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  source "$BATS_TEST_DIRNAME/test_helper/mocks.bash"
}

@test "create-project requires --url" {
  run cmd_create_project
  [ "$status" -eq 1 ]
  [[ "$output" == *"--url is required"* ]]
}

@test "create-project rejects unknown flags" {
  run cmd_create_project --url "http://example.com" --bogus value
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown flag '--bogus'"* ]]
}

@test "create-project sends videoUrl in payload" {
  MOCK_CURL_RESPONSE='{"projectId":"P123"}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_create_project --url "https://youtube.com/watch?v=abc" > /dev/null
  [[ "$(mock_curl_body)" == *'"videoUrl"'* ]]
}

@test "create-project includes model in curationPref" {
  MOCK_CURL_RESPONSE='{"projectId":"P123"}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_create_project --url "https://youtube.com/watch?v=abc" --model ClipAnything > /dev/null
  [[ "$(mock_curl_body)" == *'ClipAnything'* ]]
}
