#!/bin/bash -eu
# Prints the UDID of the iPhone simulator this checkout runs tests on, creating
# it on first use. Tests keep state on disk, such as the GRDB test database, so
# two worktrees running tests on the same simulator make each other fail.

name="Pocket Casts Tests ($(basename "$(git rev-parse --show-toplevel)"))"

udid=$(xcrun simctl list devices available --json |
  jq -r --arg name "$name" 'first(.devices[][] | select(.name == $name) | .udid) // empty')

if [ -z "$udid" ]; then
  runtime=$(xcrun simctl list runtimes available --json |
    jq '[.runtimes[] | select(.platform == "iOS")] | max_by(.version | split(".") | map(tonumber))')
  # The newest iPhone comes first
  device_type=$(jq -r 'first(.supportedDeviceTypes[] | select(.productFamily == "iPhone")) | .identifier' <<< "$runtime")
  udid=$(xcrun simctl create "$name" "$device_type" "$(jq -r .identifier <<< "$runtime")")
fi

echo "$udid"
