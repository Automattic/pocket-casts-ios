---
name: cross-platform
description: "Cross-platform codebase exploration for Pocket Casts. Use when asked about Web, iOS, or Android implementation of a feature, or when comparing implementations across platforms."
---

# Cross-Platform Codebase Exploration

The other platforms are sibling repos of the main iOS checkout (not worktrees):

| Platform | Repo | Trunk branch |
|----------|------|--------------|
| Web | `$ROOT/../pocket-casts-webplayer` | `develop` |
| Android | `$ROOT/../pocket-casts-android` | `main` |

In a worktree, `$ROOT` is the main checkout: `ROOT=$(git worktree list --porcelain | head -n 1 | awk '{print $2}')`.

## Before exploring

1. Read the repo's `CLAUDE.md`.
2. Check `git status --short` and `git branch --show-current`. If there are uncommitted changes, **ask the user** whether to stash, discard or abort.
3. Pick the branch: a PR's branch if the user named one; otherwise pull if on the trunk branch, or **ask the user** whether to switch to trunk or stay.
4. `git checkout <branch>` if switching, then `git pull`.

## What to focus on

Logic flow and architecture, state transitions, data models, API endpoints and payloads, feature flags and configuration, and the differences between platforms. Avoid language-specific syntax unless it explains behavior.
