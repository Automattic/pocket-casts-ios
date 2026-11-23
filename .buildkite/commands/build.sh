#!/bin/bash -eu

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- Build & Test"
bundle exec fastlane test

save_swiftpm_cache --package-resolved Modules/Package.resolved
