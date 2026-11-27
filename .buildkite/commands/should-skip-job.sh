#!/bin/bash -eu

# Usage: should-skip-job.sh <job>
# Prints the reason to skip the job, or `false` to run it. Exits 0 either way, and 15 for invalid arguments.
# `shared-pipeline-vars` exports the result as SKIP_<JOB TYPE>, used as the step's `skip:` (`false` runs the step).
# Only webhook PR builds filter changed files. POCKET_CASTS_CI_FULL_BUILD=1 forces a full run.

run_job() { echo false; exit 0; }

job="${1:-}"
case "$job" in
  build|ios-tests|tvos-build|localization|themes|fastlane-tests) ;;
  *) echo "Unknown job type: $job" >&2; exit 15 ;;
esac
[[ "${POCKET_CASTS_CI_FULL_BUILD:-}" != 1 ]] || run_job
if [[ ! "${BUILDKITE_PULL_REQUEST:-}" =~ ^[0-9]+$ ]]; then
  if [[ "$job" == fastlane-tests ]]; then
    echo "Fastlane helper tests only run on pull requests"
    exit 0
  fi
  run_job
fi
[[ "${BUILDKITE_SOURCE:-}" == webhook ]] || run_job

# Preserve the existing documentation/tooling exclusions for app builds.
SKIP_PATTERNS=(
  '*.md' '*.po' '*.pot' 'podcasts/Resources/release_notes.txt' '.gitignore' 'config/Version.xcconfig'
  'fastlane/*' 'Gemfile' 'Gemfile.lock' 'docs/*'
)
REQUIRED_PATTERNS=()
case "$job" in
  ios-tests) SKIP_PATTERNS+=('Pocket Casts TV App/*') ;;
  tvos-build)
    # tvOS shares production sources with iOS, but its archive doesn't build tests.
    SKIP_PATTERNS+=('PocketCastsTests/*' 'Modules/Tests/*')
    ;;
  localization)
    # lint_localized_strings_format installs gems and runs the Fastfile's GlotPress lane.
    REQUIRED_PATTERNS=(
      '*.strings' '*.stringsdict' 'fastlane/Fastfile' 'fastlane/Appfile' 'fastlane/lib/*'
      'Gemfile' 'Gemfile.lock' '.bundle/config' '.ruby-version' '.xcode-version' '.buildkite/*'
    )
    ;;
  themes)
    # env -i uses only the script, CSV and system Ruby from the selected image.
    REQUIRED_PATTERNS=('scripts/themes/*' '.buildkite/*' '.xcode-version')
    ;;
  fastlane-tests)
    REQUIRED_PATTERNS=('fastlane/*' '*.rb' 'Gemfile' 'Gemfile.lock' '.ruby-version' '.buildkite/*')
    ;;
esac

if [[ ${#REQUIRED_PATTERNS[@]} -gt 0 ]]; then
  # An empty/failed diff must run the check too, not look like "no matching inputs".
  pr_changed_files || run_job
  relevant=$(pr_changed_files --stdout --any-match "${REQUIRED_PATTERNS[@]}") || run_job
  [[ "$relevant" == false ]] || run_job
else
  # Empty diffs, errors and unknown paths run builds: skipping requires success.
  pr_changed_files --all-match "${SKIP_PATTERNS[@]}" || run_job
fi

echo "No relevant files changed"
