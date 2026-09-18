#!/bin/bash -eu
# Prints the pass/fail counts and failing tests of an .xcresult bundle.

results=$1

if ! summary=$(xcrun xcresulttool get test-results summary --path "$results" --compact 2>/dev/null); then
  echo "No test results in $results"
  exit 0
fi

jq -r '
  "\(.result): \(.passedTests) passed, \(.failedTests) failed, \(.skippedTests) skipped, \(.expectedFailures) expected failures",
  (.testFailures[] | "  \(.targetName)/\(.testIdentifierString): \(.failureText)")
' <<< "$summary"
echo "Results: $results"
