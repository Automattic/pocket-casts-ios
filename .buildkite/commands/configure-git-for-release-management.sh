#!/bin/bash -eu

# Git command line client is not configured in Buildkite. Temporarily, we configure it in each step.
# Later on, we should be able to configure the agent instead.
add_host_to_ssh_known_hosts github.com
git config --global user.email "mobile+wpmobilebot@automattic.com"
git config --global user.name "Automattic Release Bot"
