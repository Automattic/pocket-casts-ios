#!/usr/bin/env bash

set -euo pipefail

echo "--- :closed_lock_with_key: Installing a8c-secrets (PROBE: install only, no decrypt)"
curl -fsSL https://raw.githubusercontent.com/Automattic/a8c-secrets/main/install.sh | bash
# The installer puts the binary in ~/.local/bin, which isn't on the agent's PATH.
export PATH="$HOME/.local/bin:$PATH"
# PROBE: decrypt intentionally omitted — `before_all` in the Fastfile now owns it,
# to test whether the binary is reachable from the parent lane process.
