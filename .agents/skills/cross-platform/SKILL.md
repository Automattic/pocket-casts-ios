---
name: cross-platform
description: "Cross-platform codebase exploration for Pocket Casts. Use when asked about Web, iOS, or Android implementation of a feature, or when comparing implementations across platforms."
---

# Cross-Platform Codebase Exploration

## Repository Locations

Other platform repos are siblings of the root iOS repo (not worktrees):

| Platform | Relative to project root | Trunk Branch |
|----------|--------------------------|--------------|
| Web | `../pocket-casts-webplayer/` | `develop` |
| Android | `../pocket-casts-android/` | `main` |

## Finding Repos (Worktree-Safe)

If working in a worktree, first find the root iOS repo:

```bash
# Get root repo path (works in both root and worktree)
# --porcelain output is stable for scripting; first entry is always the main worktree
ROOT=$(git worktree list --porcelain | head -n 1 | awk '{print $2}')

# Platform repos are siblings of the root
WEB_REPO="$ROOT/../pocket-casts-webplayer"
ANDROID_REPO="$ROOT/../pocket-casts-android"
```

## Before Exploring

Each repository contains a `CLAUDE.md` at its root. **Read it first** to understand architecture and conventions.

## Branch Sync Procedure

Before exploring code:

1. **Navigate to repo** and check current state:
   ```bash
   cd "$WEB_REPO"  # or $ANDROID_REPO
   git status --short
   git branch --show-current
   ```

2. **If uncommitted/unstaged changes exist** → **ask the user**: stash them, discard, or abort?

3. **Determine target branch**:
   - If user specified a PR → check out that PR's branch
   - If on `develop` (Web) `main` (Android) or `trunk` (iOS) → pull latest
   - If on a different branch → **ask the user**: switch to main/trunk, or stay on current branch?

4. **Sync the branch**:
   ```bash
   git checkout <branch>  # if switching
   git pull
   ```

## What to Focus On

When comparing or describing implementations:

- Logic flow and feature architecture
- State transitions
- DTOs / data models
- API usage, endpoints, request/response structures
- Feature flags and configuration patterns
- Cross-platform differences and similarities

Avoid language-specific syntax unless necessary to explain behavior.

## Example Queries

- "How does iOS handle Up Next syncing?"
- "Compare podcast following between Android and Web"
- "What endpoints does the Server use for Up Next sync?"
- "How are feature flags structured on iOS vs Android?"
