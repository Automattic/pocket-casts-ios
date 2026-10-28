#!/bin/bash -eu

# VALIDATION ONLY — do not merge. Bypasses the skip and asserts on the fastlane output.
# A deliberately failing test makes xcodebuild reach the diagnostics-collection path.

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Build & Test"
log=$(mktemp)
set -o pipefail
start=$SECONDS
set +e
bundle exec fastlane test 2>&1 | tee "$log"
status=$?
set -e
echo "fastlane test exited $status after $((SECONDS - start)) s"

echo "--- Validate diagnostics collection flag"
failed=0
if grep -q -- '-collect-test-diagnostics never' "$log"; then
  echo "PASS: xcodebuild invoked with -collect-test-diagnostics never"
else
  echo "FAIL: xcodebuild was not invoked with -collect-test-diagnostics never"
  failed=1
fi

if grep -q 'testDeliberateFailureToTriggerDiagnosticsCollection' "$log" && [ "$status" -ne 0 ]; then
  echo "PASS: the deliberate test failure happened"
else
  echo "FAIL: the deliberate test failure did not happen, so the diagnostics path was not exercised"
  failed=1
fi

if grep -q -E 'Timed out after 600.0 seconds|Failure collecting diagnostics' "$log"; then
  echo "FAIL: simulator diagnostics collection still ran"
  failed=1
else
  echo "PASS: no simulator diagnostics collection"
fi

exit "$failed"
