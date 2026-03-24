#!/usr/bin/env bash
# Shared helpers for OpusClip CLI

# shellcheck disable=SC2034  # used by sourcing scripts
VERSION="1.1.0"

die()  { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed"; }

# Pretty-print JSON
output() { jq .; }

need curl
need jq
