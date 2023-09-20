#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
bundle install

echo "--- Install Pods"
# We need the pods because that's where SwiftLint (used by Danger) comes from
bundle exec pod install --allow-root

echo "--- Running Danger: PR Check"
bundle exec danger --fail-on-errors=true --dangerfile=.buildkite/danger/Dangerfile --remove-previous-comments --danger_id=pr-check
