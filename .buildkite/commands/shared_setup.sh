#!/bin/bash -eu

echo "--- :ruby: Setting up Ruby tools"
install_gems

# The push/pop is a workaround for tooling not supporting a Package.swift path.
# Note that neither ours nor Apple's tooling does.
pushd "$(dirname "${BASH_SOURCE[0]}")/../../Modules"
echo "--- :swift: Installing Swift Package Manager Dependencies"
install_swiftpm_dependencies
popd
