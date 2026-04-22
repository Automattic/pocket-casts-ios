#!/usr/bin/env bash

set -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_app_store_connect_tvos

echo "--- :rocket: Uploading to TestFlight"
echo "NOTE: This TestFlight upload is temporary; it's here only to validate the end-to-end tvOS signing and delivery setup."
echo "Remove it from this step once the pipeline is confirmed working."
bundle exec fastlane upload_app_store_connect_build_to_testflight_tvos
