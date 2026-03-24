#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
}

@test "api_key returns key when set" {
  export OPUSCLIP_API_KEY="my-secret-key"
  run api_key
  [ "$status" -eq 0 ]
  [ "$output" = "my-secret-key" ]
}

@test "api_key dies when not set" {
  unset OPUSCLIP_API_KEY
  run api_key
  [ "$status" -eq 1 ]
  [[ "$output" == *"OPUSCLIP_API_KEY is not set"* ]]
  [[ "$output" == *"Enterprise plan"* ]]
}

@test "API_BASE defaults to production URL" {
  unset OPUSCLIP_API_URL
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  [ "$API_BASE" = "https://api.opus.pro/api" ]
}

@test "API_BASE can be overridden" {
  export OPUSCLIP_API_URL="https://staging.opus.pro/api"
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  [ "$API_BASE" = "https://staging.opus.pro/api" ]
}
