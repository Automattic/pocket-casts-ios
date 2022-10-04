#!/bin/bash -eu

echo "--- :rubygems: Set up Gems"
install_gems

echo "--- Install Pods"
# We need the pods because that's where SwiftLint (used by Danger) comes from
# FIXME: SwiftLint is not used in Danger yet, but we aim to get it there soon.
install_cocoapods

echo "--- :warning: Run Danger"
bundle exec danger --fail-on-errors=true
