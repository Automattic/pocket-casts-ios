#!/bin/bash -eu

echo "--- :ruby: Setting up Ruby tools"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :xcode: :hammer: Delete Package.resolved from xcodeproj folder"
# It appears that when a project has both the xcodeproj and xcworkspace folder in its root,
# the "xcodebuild -resolvePackageDependencies" command (as of Xcode 15.4) will generate the Package.resolved file in both folders.
# This can become a problem when packages are updated via Xcode and only the resolved file in the workspace folder is updated.
#
# See failure in https://buildkite.com/automattic/pocket-casts-ios/builds/7634#019113ca-d4bd-4838-b93a-aae0e4a0528f
#
# To avoid this issue, let's remove the file project file, if any.
EXTRA_RESOLVED_FILE_PATH="$(dirname "${BASH_SOURCE[0]}")/../../podcasts.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
rm "$EXTRA_RESOLVED_FILE_PATH" || echo "No resolved file found at $EXTRA_RESOLVED_FILE_PATH"

echo "--- :swift: Installing Swift Package Manager Dependencies"
install_swiftpm_dependencies
