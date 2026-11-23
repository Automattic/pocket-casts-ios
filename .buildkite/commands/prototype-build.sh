#!/bin/bash -eu

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_enterprise
