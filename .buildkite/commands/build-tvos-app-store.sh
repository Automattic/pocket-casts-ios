#!/usr/bin/env bash

set -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :hammer_and_wrench: Building"
# CI-driven tvOS uploads use a low 0.x build number. App Store Connect may
# reject these after a release build already exists for the same version.
bundle exec fastlane build_app_store_connect_tvos "build_number:0.$BUILDKITE_BUILD_NUMBER"
