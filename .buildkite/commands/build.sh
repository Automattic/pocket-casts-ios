#!/bin/bash -eu

# VALIDATION ONLY — do not merge. Bypasses the skip and asserts on the fastlane output.

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Build & Test"
log=$(mktemp)
set -o pipefail
bundle exec fastlane test 2>&1 | tee "$log"

echo "--- Validate diagnostics collection flag"
if ! grep -q -- '-collect-test-diagnostics never' "$log"; then
  echo "FAIL: xcodebuild was not invoked with -collect-test-diagnostics never"
  exit 1
fi
echo "PASS: xcodebuild invoked with -collect-test-diagnostics never"

if grep -q 'Timed out after 600.0 seconds' "$log"; then
  echo "FAIL: simulator diagnostics collection still timed out"
  exit 1
fi
echo "PASS: no simulator diagnostics timeout"
