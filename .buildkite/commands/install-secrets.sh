#!/usr/bin/env bash

set -euo pipefail

# `install_a8c-secrets_binary` comes from the a8c-ci-toolkit plugin. It pins the
install_dir="$HOME/.local/bin"
install_a8c-secrets_binary --install-dir "$install_dir"
export PATH="$install_dir:$PATH"

echo "--- :closed_lock_with_key: Decrypt secrets"
a8c-secrets decrypt
