#!/usr/bin/env bash

set -euo pipefail

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :hammer_and_wrench: Building iOS"
bundle exec fastlane build_app_store_connect

mkdir -p artifacts

echo "--- :lock: Scanning the release binary"
set +e
bundle exec fastlane scan_release_binary "path:artifacts/pocket-casts.ipa" | tee artifacts/release-binary-scan.txt
status=${PIPESTATUS[0]}
set -e

if ! grep -q 'scanned ' artifacts/release-binary-scan.txt; then
  echo "The scanner did not report a result."
  exit 1
fi

exit "$status"
