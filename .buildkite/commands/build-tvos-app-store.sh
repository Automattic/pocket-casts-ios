#!/usr/bin/env bash

set -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
# The `0.` prefix keeps CI-driven builds below release build codes as builds may be
# rejected after a final release build already exists for the same version.
bundle exec fastlane build_app_store_connect_tvos "build_number:0.$BUILDKITE_BUILD_NUMBER"
