#!/bin/bash -u

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Setup Ruby tooling"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

install_gems # see bash-cache Automattic's Buildkite plugin

echo "--- Install Pods"
install_cocoapods # see bash-cache Automattic's Buildkite plugin

echo "--- Build & Test"
bundle exec fastlane test
