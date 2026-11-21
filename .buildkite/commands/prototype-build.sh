#!/bin/bash -eu

# Sentry CLI needs to be up-to-date
brew upgrade getsentry/tools/sentry-cli

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_enterprise
