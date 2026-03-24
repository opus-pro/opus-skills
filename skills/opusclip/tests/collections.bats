#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
  source "$BATS_TEST_DIRNAME/test_helper/mocks.bash"
}

@test "collections defaults to list" {
  MOCK_CURL_RESPONSE='{"data":{"list":[]}}'
  export MOCK_CURL_RESPONSE MOCK_DIR
  cmd_collections > /dev/null
  [[ "$(mock_curl_args)" == *"collections?q=mine"* ]]
}

@test "collections create requires --name" {
  run cmd_collections create
  [ "$status" -eq 1 ]
  [[ "$output" == *"--name is required"* ]]
}

@test "collections delete requires --id" {
  run cmd_collections delete
  [ "$status" -eq 1 ]
  [[ "$output" == *"--id is required"* ]]
}

@test "collections add-clip requires --id and --content-id" {
  run cmd_collections add-clip
  [ "$status" -eq 1 ]
  [[ "$output" == *"--id is required"* ]]

  run cmd_collections add-clip --id COL1
  [ "$status" -eq 1 ]
  [[ "$output" == *"--content-id is required"* ]]
}

@test "collections rejects unknown subcommand" {
  run cmd_collections badcmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown subcommand"* ]]
}
