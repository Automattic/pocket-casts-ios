#!/bin/bash -eu

echo "--- :ruby: Setting up Ruby tools"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :swift: Installing Swift Package Manager Dependencies"
# Temporarily disable `install_swiftpm_dependencies` and calling `xcodebuild -resolvePackageDependencies`
# command directly instead until we move the `.xcodeproj` to a folder other than the project root to workaround
# an issue with `xcodebuild` not using the right `Package.resolved` file (`*.xcworkspace/*` vs `*.xcodeproj/*`)
#
# install_swiftpm_dependencies
xcodebuild -resolvePackageDependencies \
  -workspace podcasts.xcworkspace \
  -scheme pocketcasts
