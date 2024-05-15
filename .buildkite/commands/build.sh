#!/bin/bash -u

echo "--- Setup Ruby tooling"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

install_gems # see bash-cache Automattic's Buildkite plugin

echo "--- Test Code Signing"
bundle exec fastlane configure_code_signing_app_store
