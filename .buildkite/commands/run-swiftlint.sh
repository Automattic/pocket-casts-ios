#!/bin/bash -u

echo "--- :swift: Running SwiftLint"

set +e
SWIFTLINT_OUTPUT=$(swiftlint lint --quiet $@ --reporter csv)
SWIFTLINT_EXIT_STATUS=$?
set -e

WARNINGS=$(echo "$SWIFTLINT_OUTPUT" | awk -F',' '$4=="Warning" {print "- `"$1":"$2"`: "$6}')
ERRORS=$(echo "$SWIFTLINT_OUTPUT" | awk -F',' '$4=="Error" {print "- `"$1":"$2"`: "$6}')

if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS"
  printf '**SwiftLint Warnings**\n%b' "$WARNINGS" | buildkite-agent annotate --style 'warning'
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS"
  printf '**SwiftLint Errors**\n%b' "$ERRORS" | buildkite-agent annotate --style 'error'
fi

exit $SWIFTLINT_EXIT_STATUS
