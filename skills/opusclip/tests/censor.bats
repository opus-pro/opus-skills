#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  source "$BATS_TEST_DIRNAME/test_helper/mocks.bash"
}

@test "censor create requires --project" {
  run cmd_censor create
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project is required"* ]]
}

@test "censor create requires --clip" {
  run cmd_censor create --project P1
  [ "$status" -eq 1 ]
  [[ "$output" == *"--clip is required"* ]]
}

@test "censor status requires --job" {
  run cmd_censor status
  [ "$status" -eq 1 ]
  [[ "$output" == *"--job is required"* ]]
}

@test "censor rejects unknown subcommand" {
  run cmd_censor badcmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown subcommand"* ]]
}
