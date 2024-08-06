#!/bin/bash -u

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Install Pods"
install_cocoapods # see bash-cache Automattic's Buildkite plugin

echo "--- Build & Test"
bundle exec fastlane test
