#!/bin/bash -eu

echo "--- :ruby: Setting up Ruby tools"
install_gems

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :swift: Installing Swift Package Manager Dependencies"
restore_swiftpm_cache --package-resolved Modules/Package.resolved
