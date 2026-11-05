#!/bin/bash -eu

# Usage: should-skip-job.sh --job-type <job>
# Returns 0 to skip, 1 to run, 15 for invalid arguments.
# Only webhook PR builds skip jobs. POCKET_CASTS_CI_FULL_BUILD=1 forces a full run.

[[ $# -eq 2 && "$1" == --job-type ]] || exit 15
job="$2"
case "$job" in
  build|ios-tests|tvos-build|localization|themes) ;;
  *) echo "Unknown job type: $job" >&2; exit 15 ;;
esac
if [[ "${POCKET_CASTS_CI_FULL_BUILD:-}" == 1 || "${BUILDKITE_SOURCE:-}" != webhook ||
      ! "${BUILDKITE_PULL_REQUEST:-}" =~ ^[0-9]+$ ]]; then
  exit 1
fi

SKIP_PATTERNS=(
  '*/README.md' '!(*/*).md' '.gitignore' 'fastlane/metadata/*' 'fastlane/metadata-tvos/*'
)
REQUIRED_PATTERNS=()
case "$job" in
  ios-tests) SKIP_PATTERNS+=('Pocket Casts TV App/*') ;;
  tvos-build)
    # tvOS shares production sources with iOS, but its archive doesn't build tests.
    SKIP_PATTERNS+=('PocketCastsTests/*' 'Modules/Tests/*')
    ;;
  localization)
    REQUIRED_PATTERNS=(
      '*.strings' '*.stringsdict' '.buildkite/*' '.xcode-version'
      'fastlane/Fastfile' 'fastlane/Appfile' 'fastlane/Pluginfile' 'fastlane/*.rb'
      'Gemfile*' '.ruby-version'
    )
    ;;
  themes)
    # env -i uses only the script, CSV and system Ruby from the selected image.
    REQUIRED_PATTERNS=('scripts/themes/*' '.buildkite/*' '.xcode-version')
    ;;
esac

# Include both sides of renames without changing the checkout's Git config.
config_index=${GIT_CONFIG_COUNT:-0}
export GIT_CONFIG_COUNT=$((config_index + 1))
export "GIT_CONFIG_KEY_${config_index}=diff.renames" "GIT_CONFIG_VALUE_${config_index}=false"

if [[ ${#REQUIRED_PATTERNS[@]} -gt 0 ]]; then
  # An empty/failed diff must run the check too, not look like "no matching inputs".
  pr_changed_files || exit 1
  relevant=$(pr_changed_files --stdout --any-match "${REQUIRED_PATTERNS[@]}") || exit 1
  [[ "$relevant" == false ]] || exit 1
else
  # Empty diffs, errors and unknown paths run builds: skipping requires success.
  pr_changed_files --all-match "${SKIP_PATTERNS[@]}" || exit 1
fi

message="Skipping ${BUILDKITE_LABEL:-$job} - no relevant files changed"
echo "$message"
if [[ "${BUILDKITE:-}" == true ]]; then
  echo "$message" | buildkite-agent annotate --style info --context "skip-${BUILDKITE_JOB_ID:-$job}" || echo 'Could not annotate skipped job' >&2
fi
exit 0
