#!/usr/bin/env bash

set -euo pipefail

echo "--- :closed_lock_with_key: Installing Secrets"
curl -fsSL https://raw.githubusercontent.com/Automattic/a8c-secrets/main/install.sh | bash
# The installer puts the binary in ~/.local/bin, which isn't on the agent's PATH.
export PATH="$HOME/.local/bin:$PATH"
bundle exec fastlane configure_secrets
