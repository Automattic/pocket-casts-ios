#!/bin/bash -eu

echo "--- Setting up Ruby tools"
install_gems

echo "--- :swift: Installing Swift Package Manager Dependencies"
install_swiftpm_dependencies
