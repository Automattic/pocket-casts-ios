#!/bin/bash -eu

# Ensure we get the latest commit of the `release/*` branch, especially to get last version bump commit before publishing the GitHub Release and creating the git tag
RELEASE_VERSION="${1:?RELEASE_VERSION parameter missing}"
"$(dirname "${BASH_SOURCE[0]}")/checkout-release-branch.sh" "$RELEASE_VERSION"

BETA_RELEASE=${2:-true} # use second call param, default to true for safety
RELEASE_PLATFORM="${3:-${RELEASE_PLATFORM:-ios}}"
NOTIFY_SLACK="${4:-${NOTIFY_SLACK:-true}}"
CREATE_GITHUB_RELEASE="${5:-${CREATE_GITHUB_RELEASE:-true}}"

case "$RELEASE_PLATFORM" in
  ios)
    PLATFORM_NAME="iOS"
    IPA_PATH="artifacts/pocket-casts.ipa"
    DSYM_PATH="artifacts/pocket-casts.app.dSYM.zip"
    ARCHIVE_ZIP_PATH="artifacts/pocket-casts.xcarchive.zip"
    SENTRY_ANNOTATION_CONTEXT="sentry-failure-ios"
    TESTFLIGHT_LANE="upload_app_store_connect_build_to_testflight"
    ;;
  tvos)
    PLATFORM_NAME="tvOS"
    IPA_PATH="artifacts/pocket-casts-tvos.ipa"
    DSYM_PATH="artifacts/pocket-casts-tvos.app.dSYM.zip"
    ARCHIVE_ZIP_PATH="artifacts/pocket-casts-tvos.xcarchive.zip"
    SENTRY_ANNOTATION_CONTEXT="sentry-failure-tvos"
    TESTFLIGHT_LANE="upload_app_store_connect_build_to_testflight_tvos"
    ;;
  *)
    echo "Unsupported RELEASE_PLATFORM: $RELEASE_PLATFORM. Expected 'ios' or 'tvos'." >&2
    exit 1
    ;;
esac

echo "Running $0 with BETA_RELEASE = $BETA_RELEASE, RELEASE_PLATFORM = $RELEASE_PLATFORM, NOTIFY_SLACK = $NOTIFY_SLACK, CREATE_GITHUB_RELEASE = $CREATE_GITHUB_RELEASE..."

echo "--- :arrow_down: Downloading Artifacts"
STEP=release_build
buildkite-agent artifact download "$IPA_PATH" . --step "$STEP"
buildkite-agent artifact download "$DSYM_PATH" . --step "$STEP"
buildkite-agent artifact download "$ARCHIVE_ZIP_PATH" . --step "$STEP"

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

if [[ "$CREATE_GITHUB_RELEASE" != "true" ]]; then
  echo "--- :github: Verifying GitHub Release exists"
  bundle exec fastlane ensure_github_release_exists beta_release:"$BETA_RELEASE"
fi

echo "--- :testflight: Uploading $PLATFORM_NAME to TestFlight"
bundle exec fastlane "$TESTFLIGHT_LANE" ipa_path:"$IPA_PATH"

upload_symbols() {
  local platform="$1"
  local dsym_path="$2"
  local annotation_context="$3"

  echo "--- :arrow_up: Uploading $platform dSYM to Sentry"
  set +e
  bundle exec fastlane symbols_upload "dsym_path:$dsym_path"
  local sentry_upload_status=$?
  set -e

  if [[ $sentry_upload_status -ne 0 ]]; then
    echo "^^^ +++ Failed to upload $platform dSYM to Sentry! Make sure to download dSYM from the build step artifacts and upload manually."
    buildkite-agent annotate --style error --context "$annotation_context" "Failed to upload $platform dSYM to Sentry! Make sure to download dSYM from the build step artifacts and upload manually."
  fi
}

upload_symbols "$PLATFORM_NAME" "$DSYM_PATH" "$SENTRY_ANNOTATION_CONTEXT"

echo "--- :github: Updating GitHub Release"
bundle exec fastlane create_release_on_github beta_release:"$BETA_RELEASE" archive_zip_path:"$ARCHIVE_ZIP_PATH" notify_slack:"$NOTIFY_SLACK" create_release:"$CREATE_GITHUB_RELEASE"
