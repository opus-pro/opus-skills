#!/usr/bin/env bats

OPUSCLIP="$BATS_TEST_DIRNAME/../scripts/opusclip"

@test "help outputs usage" {
  run bash "$OPUSCLIP" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"opusclip"* ]]
  [[ "$output" == *"COMMANDS"* ]]
}

@test "version outputs semver" {
  run bash "$OPUSCLIP" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^opusclip\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "unknown command shows error" {
  run bash "$OPUSCLIP" nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown command"* ]]
}

@test "help lists all commands" {
  run bash "$OPUSCLIP" help
  [[ "$output" == *"submit"* ]]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"describe"* ]]
  [[ "$output" == *"upload"* ]]
  [[ "$output" == *"collections"* ]]
  [[ "$output" == *"censor"* ]]
  [[ "$output" == *"post"* ]]
  [[ "$output" == *"share"* ]]
  [[ "$output" == *"templates"* ]]
  [[ "$output" == *"preview"* ]]
  [[ "$output" == *"storyboard"* ]]
  [[ "$output" == *"trim"* ]]
}

@test "collections rejects unknown subcommand" {
  run bash "$OPUSCLIP" collections badcmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown subcommand"* ]]
}

@test "censor rejects unknown subcommand" {
  run bash "$OPUSCLIP" censor badcmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown subcommand"* ]]
}

@test "share requires --project" {
  export OPUSCLIP_API_KEY="test-key"
  run bash "$OPUSCLIP" share
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project is required"* ]]
}

@test "describe requires --project" {
  export OPUSCLIP_API_KEY="test-key"
  run bash "$OPUSCLIP" describe
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project is required"* ]]
}

@test "trim requires --project" {
  export OPUSCLIP_API_KEY="test-key"
  run bash "$OPUSCLIP" trim
  [ "$status" -eq 1 ]
  [[ "$output" == *"--project is required"* ]]
}
