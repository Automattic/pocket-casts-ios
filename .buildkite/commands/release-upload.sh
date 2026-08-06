#!/bin/bash -eu

# Ensure we get the latest commit of the `release/*` branch, especially to get last version bump commit before publishing the GitHub Release and creating the git tag
RELEASE_VERSION="${1:?RELEASE_VERSION parameter missing}"

BETA_RELEASE=${2:-true} # use second call param, default to true for safety
RELEASE_PLATFORM="${3:-${RELEASE_PLATFORM:-}}"
NOTIFY_SLACK="${4:-${NOTIFY_SLACK:-}}"
CREATE_GITHUB_RELEASE="${5:-${CREATE_GITHUB_RELEASE:-}}"

if [[ -z "$RELEASE_PLATFORM" ]]; then
  echo "RELEASE_PLATFORM parameter missing. Expected 'ios' or 'tvos'." >&2
  exit 1
fi

case "$RELEASE_PLATFORM" in
  ios)
    PLATFORM_NAME="iOS"
    IPA_PATH="artifacts/pocket-casts.ipa"
    DSYM_PATH="artifacts/pocket-casts.app.dSYM.zip"
    ARCHIVE_ZIP_PATH="artifacts/pocket-casts.xcarchive.zip"
    SENTRY_ANNOTATION_CONTEXT="sentry-failure-ios"
    TESTFLIGHT_LANE="upload_app_store_connect_build_to_testflight"
    TESTFLIGHT_LANE_ARGS=(ipa_path:"$IPA_PATH")
    ;;
  tvos)
    PLATFORM_NAME="tvOS"
    IPA_PATH="artifacts/pocket-casts-tvos.ipa"
    DSYM_PATH="artifacts/pocket-casts-tvos.app.dSYM.zip"
    ARCHIVE_ZIP_PATH="artifacts/pocket-casts-tvos.xcarchive.zip"
    SENTRY_ANNOTATION_CONTEXT="sentry-failure-tvos"
    TESTFLIGHT_LANE="upload_app_store_connect_build_to_testflight_tvos"
    TESTFLIGHT_LANE_ARGS=(ipa_path:"$IPA_PATH" distribute_external:"$BETA_RELEASE")
    ;;
  *)
    echo "Unsupported RELEASE_PLATFORM: $RELEASE_PLATFORM. Expected 'ios' or 'tvos'." >&2
    exit 1
    ;;
esac

if [[ -z "$NOTIFY_SLACK" ]]; then
  if [[ "$RELEASE_PLATFORM" == "ios" ]]; then
    NOTIFY_SLACK="true"
  else
    NOTIFY_SLACK="false"
  fi
fi

if [[ -z "$CREATE_GITHUB_RELEASE" ]]; then
  if [[ "$RELEASE_PLATFORM" == "ios" ]]; then
    CREATE_GITHUB_RELEASE="true"
  else
    CREATE_GITHUB_RELEASE="false"
  fi
fi

echo "Running $0 with BETA_RELEASE = $BETA_RELEASE, RELEASE_PLATFORM = $RELEASE_PLATFORM, NOTIFY_SLACK = $NOTIFY_SLACK, CREATE_GITHUB_RELEASE = $CREATE_GITHUB_RELEASE..."

checkout_release_branch "$RELEASE_VERSION"

echo "--- :arrow_down: Downloading Artifacts"
STEP=release_build
buildkite-agent artifact download "$IPA_PATH" . --step "$STEP"
buildkite-agent artifact download "$DSYM_PATH" . --step "$STEP"
buildkite-agent artifact download "$ARCHIVE_ZIP_PATH" . --step "$STEP"

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :github: Updating GitHub Release"
bundle exec fastlane create_release_on_github beta_release:"$BETA_RELEASE" archive_zip_path:"$ARCHIVE_ZIP_PATH" notify_slack:false create_release:"$CREATE_GITHUB_RELEASE"

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

echo "--- :testflight: Uploading $PLATFORM_NAME to TestFlight"
bundle exec fastlane "$TESTFLIGHT_LANE" "${TESTFLIGHT_LANE_ARGS[@]}"

if [[ "$NOTIFY_SLACK" == "true" ]]; then
  echo "--- :slack: Notifying Slack"
  bundle exec fastlane notify_release_on_slack beta_release:"$BETA_RELEASE"
else
  echo "--- :slack: Skipping Slack notification"
fi
