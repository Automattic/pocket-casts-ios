#!/usr/bin/env bash

set -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :arrow_down: Downloading tvOS App Store Build"
buildkite-agent artifact download "artifacts/*.ipa" . --step build_tvos_app_store
buildkite-agent artifact download "artifacts/*.app.dSYM.zip" . --step build_tvos_app_store

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :rocket: Uploading to TestFlight"
bundle exec fastlane upload_app_store_connect_build_to_testflight_tvos
