#!/bin/bash -eu

# Ensure we get the latest commit of the `release/*` branch, especially to get last version bump commit before building the release
RELEASE_VERSION="${1:?RELEASE_VERSION parameter missing}"
RELEASE_PLATFORM="${2:-${RELEASE_PLATFORM:-}}"

if [[ -z "$RELEASE_PLATFORM" ]]; then
  echo "RELEASE_PLATFORM parameter missing. Expected 'ios' or 'tvos'." >&2
  exit 1
fi

checkout_release_branch "$RELEASE_VERSION"

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

case "$RELEASE_PLATFORM" in
  ios)
    echo "--- :hammer_and_wrench: Building iOS"
    bundle exec fastlane build_app_store_connect
    ;;
  tvos)
    echo "--- :hammer_and_wrench: Building tvOS"
    bundle exec fastlane build_app_store_connect_tvos
    ;;
  *)
    echo "Unsupported RELEASE_PLATFORM: $RELEASE_PLATFORM. Expected 'ios' or 'tvos'." >&2
    exit 1
    ;;
esac
