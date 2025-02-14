#!/bin/bash -eu

# Script to checkout a specific release branch
# Usage: ./checkout-release-branch.sh <RELEASE_VERSION>

RELEASE_VERSION="${1:?RELEASE_VERSION parameter missing}"
BRANCH_NAME="release/${RELEASE_VERSION}"

# Buildkite, by default, checks out a specific commit. But given this step will be run on a CI build that will
# first push a commit to do the version bump, before `pipeline upload`-ing the job calling this script, we need
# to checkout the `release/` branch explicitly here, to ensure this job would include that extra commit
# instead of running on the initial commit the whole CI build/pipeline was initially triggered on.
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
git pull
