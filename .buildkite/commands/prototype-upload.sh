#!/bin/bash -eu

# Sentry CLI needs to be up-to-date
brew upgrade getsentry/tools/sentry-cli

echo "--- :arrow_down: Downloading Prototype Build"
buildkite-agent artifact download "artifacts/*.ipa" . --step build_prototype
buildkite-agent artifact download "artifacts/*.app.dSYM.zip" . --step build_prototype

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :hammer_and_wrench: Uploading"
bundle exec fastlane upload_enterprise
