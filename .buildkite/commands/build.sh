#!/bin/bash -u

echo "--- Set up SPM"
# We'd like to use this, but it doesn't work yet. See
# https://github.com/Automattic/bash-cache-buildkite-plugin/issues/20 ...
#
PRIVATE_REPO_FETCH_KEY_NAME=private_repos_key
add_ssh_key_to_agent "$PRIVATE_REPOS_BOT_KEY" $PRIVATE_REPO_FETCH_KEY_NAME
PRIVATE_REPO_FETCH_KEY=~/.ssh/$PRIVATE_REPO_FETCH_KEY_NAME

add_host_to_ssh_known_hosts 'github.com'

# Configuring Git to use the custom SSH key for the pocket-casts-ios-utils
# private repo. This is a different key than the one we use to fetch the Pocket
# Casts repo itself. If all goes well, the Git instance Xcode will use will
# adopt this setting, too (see IDEPackageSupportUseBuiltinSCM below).
#
# See https://stackoverflow.com/a/38474137/809944
export GIT_SSH_COMMAND="ssh -i $PRIVATE_REPO_FETCH_KEY -o IdentitiesOnly=yes"
echo "Git SSH command is $GIT_SSH_COMMAND"

echo "--- :swift: Installing Swift Package Manager Dependencies"
install_swiftpm_dependencies

echo "--- Setup Ruby tooling"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

install_gems # see bash-cache Automattic's Buildkite plugin

echo "--- Install Pods"
install_cocoapods # see bash-cache Automattic's Buildkite plugin

echo "--- Build & Test"
bundle exec fastlane test
