#!/bin/bash -eu

# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_enterprise
