---
name: feature-flag
description: Adds a feature flag and fences off code with it
---

1. In `Modules/Sources/PocketCastsUtils/Feature Flags/FeatureFlag.swift`, add a `case` with a `///` comment at the end of the enum, and add it to the exhaustive `switch` in `default` (`false`, or `BuildEnvironment.current == .debug` for debug builds only).
2. Fence off the branch's changes (`git diff $(git merge-base HEAD origin/trunk)`) with `if FeatureFlag.<name>.enabled`, keeping the existing behavior in the `else` branch.
3. Build the app.
