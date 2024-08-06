#!/bin/bash -eu

echo "--- :ruby: Setting up Ruby tools"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :swift: Installing Swift Package Manager Dependencies"
# Disabled until the xcodeproj will be in a folder other than the project root
#
# install_swiftpm_dependencies
xcodebuild -resolvePackageDependencies \
  -workspace podcasts.xcworkspace \
  -scheme pocketcasts
