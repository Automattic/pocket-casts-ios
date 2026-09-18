#!/bin/bash
# PostToolUse hook: autocorrects an edited Swift file, then reports the
# violations SwiftLint can't fix. Exit code 2 sends stderr back to Claude.

file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.swift && -f "$file" ]] || exit 0

# Use the config of the checkout that owns the file, which may be a worktree.
root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.swiftlint.yml" ] || exit 0

version=$(sed -n 's/^swiftlint_version: *//p' "$root/.swiftlint.yml")
binary=BuildTools/.build/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint

find_swiftlint() {
  for dir in "$root" "$CLAUDE_PROJECT_DIR"; do
    if [ -x "$dir/$binary" ] && [ "$("$dir/$binary" version)" = "$version" ]; then
      echo "$dir/$binary"
      return 0
    fi
  done
  return 1
}

# Resolving BuildTools downloads the binary pinned by `swiftlint_version`.
if ! swiftlint=$(find_swiftlint); then
  swift package --package-path "$root/BuildTools" --manifest-cache none resolve >/dev/null 2>&1
  if ! swiftlint=$(find_swiftlint); then
    echo "SwiftLint $version is missing from $root/BuildTools/.build; run \`make lint\` once." >&2
    exit 1
  fi
fi

cd "$root" || exit 1
"$swiftlint" --fix --quiet --force-exclude --config .swiftlint.yml "$file" >/dev/null 2>&1
violations=$("$swiftlint" lint --quiet --force-exclude --config .swiftlint.yml "$file" 2>&1)
# The config excludes the file.
[[ "$violations" == "Error: No lintable files found"* ]] && exit 0
if [ -n "$violations" ]; then
  echo "$violations" >&2
  exit 2
fi
