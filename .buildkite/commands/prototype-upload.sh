#!/bin/bash -eu

# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

echo "--- :arrow_down: Downloading Prototype Build"
buildkite-agent artifact download "artifacts/*.ipa" . --step build_prototype
buildkite-agent artifact download "artifacts/*.app.dSYM.zip" . --step build_prototype

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Uploading"
bundle exec fastlane upload_enterprise
