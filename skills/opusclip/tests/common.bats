#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/setup.bash"
}

@test "VERSION is set" {
  [[ -n "$VERSION" ]]
  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "die prints error to stderr and exits 1" {
  run die "something went wrong"
  [ "$status" -eq 1 ]
  [ "$output" = "error: something went wrong" ]
}

@test "output pretty-prints JSON" {
  result=$(echo '{"a":1}' | output)
  [[ "$result" == *'"a": 1'* ]]
}
