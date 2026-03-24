#!/usr/bin/env bash
# Common test setup — source libs and mock API key

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"

# Source libraries (provides die, need, api_key, api_post, etc.)
source "$SCRIPT_DIR/lib/api.sh"

# Source all commands
for _cmd_file in "$SCRIPT_DIR/commands/"*.sh; do
  source "$_cmd_file"
done
unset _cmd_file

# Set a fake API key so api_key() doesn't die
export OPUSCLIP_API_KEY="test-key-for-bats"
