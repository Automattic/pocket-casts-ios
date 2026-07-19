#!/usr/bin/env bash

set -euo pipefail

# Pinned a8c-secrets release and the SHA-256 of its macOS arm64 asset. Bump both
# together: `shasum -a 256` on the asset downloaded from the release page.
#
# We install the release binary ourselves, rather than piping upstream's `install.sh`
# from `main` into `bash`, so the secrets tooling can't change under us without a
# reviewed diff here. See https://github.com/Automattic/pocket-casts-ios/pull/4731#discussion_r3565275428.
A8C_SECRETS_VERSION='1.0.0'
A8C_SECRETS_SHA256='2b59604261053d2b57a805c53e3b727c43b750e821b587c0492dee7f717bab24'

echo "--- :closed_lock_with_key: Installing Secrets"

# Upstream publishes no x86_64 macOS build, so fail with the reason rather than on a
# baffling checksum mismatch.
arch="$(uname -m)"
if [[ "$arch" != 'arm64' ]]; then
  echo "a8c-secrets $A8C_SECRETS_VERSION has no macOS build for $arch." >&2
  exit 1
fi

asset="a8c-secrets-aarch64-apple-darwin-$A8C_SECRETS_VERSION"
install_dir="$HOME/.local/bin"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl --location --silent --show-error --fail \
  --output "$tmp_dir/a8c-secrets" \
  "https://github.com/Automattic/a8c-secrets/releases/download/$A8C_SECRETS_VERSION/$asset"

actual_sha256="$(shasum -a 256 "$tmp_dir/a8c-secrets" | cut -d ' ' -f1)"
if [[ "$actual_sha256" != "$A8C_SECRETS_SHA256" ]]; then
  echo "Checksum mismatch for $asset" >&2
  echo "  expected: $A8C_SECRETS_SHA256" >&2
  echo "  actual:   $actual_sha256" >&2
  exit 1
fi

install -d "$install_dir"
install -m 755 "$tmp_dir/a8c-secrets" "$install_dir/a8c-secrets"

# The binary lands in ~/.local/bin, which isn't on the agent's PATH.
export PATH="$install_dir:$PATH"

bundle exec fastlane configure_secrets
