#!/bin/bash -u

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Build & Test"
bundle exec fastlane test
