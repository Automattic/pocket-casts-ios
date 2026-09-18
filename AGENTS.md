## Commands

```bash
make format          # SwiftLint autocorrect over the whole repo
make build_staging
make clean
make test_staging    # PocketCastsTests
make test_staging ONLY_TESTING=PocketCastsTests/YourTestClass/testMethodName
```

### Building in a Worktree

Each worktree build creates 10–14 GB of DerivedData. Use a private one and delete it with the worktree:

```bash
xcodebuild -project podcasts.xcodeproj -scheme "Pocket Casts Staging" -configuration StagingDebug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "/tmp/DerivedData-$(basename "$PWD")" \
  ARCHS=arm64 COMPILER_INDEX_STORE_ENABLE=NO build
```

### Running Module Tests

Run module tests with the `Modules-Package` scheme from `Modules/`: one class takes ~16 s, against 47 s app-hosted. `swift test` doesn't work, since it builds for macOS and the GoogleCast, EventHorizon and Fingerprint frameworks are iOS-only.

```bash
cd Modules && xcodebuild test -scheme Modules-Package \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  -only-testing:PocketCastsServerTests/YourTestClass
```

## Architecture

`Modules/Package.swift` is a single Swift package, with targets in `Modules/Sources/` and tests in `Modules/Tests/`:

- **PocketCastsDataModel** - GRDB persistence for podcasts, episodes and playback, using the `@GRDBRecord` macros from **GRDBMacros**. All data access goes through `DataManager.sharedManager` (`Public/DataManager.swift`).
- **PocketCastsServer** - API layer using Protocol Buffers.
- **PocketCastsUtils** - Shared utilities, including feature flags and localization helpers.
- **PocketCastsAnalytics** - `Analytics`, the Tracks and logging adapters, and the A/B test provider. Add new events to `AnalyticsEvent.swift`.
- **EndOfYear** - End of Year stories.
- **XcodeSupport** - Per-Xcode-target libraries that pull in each app target's package dependencies.

The app lives in `podcasts/` (UIKit with XIBs and storyboards, plus SwiftUI; organized by feature), with unit tests in `PocketCastsTests/`. Other targets: `Pocket Casts Watch App/`, `WidgetExtension/`, App Clip, CarPlay and TV. `BuildTools/` holds the SwiftLint and SwiftGen plugins.

## Localization

Add strings to `podcasts/en.lproj/Localizable.strings` with a comment describing the context and placeholders; SwiftGen generates the `L10n` enum on build (`L10n.featureDescriptionKey(value)`).

- Keys are snake_case: `feature_relevantIdentifier_description`
- Use positional specifiers (`%1$@`, `%2$@`), never string interpolation
- Handle plurals with separate `_singular`/`_plural` keys
- Never use `LocalizedStringKey` in SwiftUI; use `L10n`

## Code Style

SwiftLint custom rules, for RTL support: use `naturalContentHorizontalAlignment` instead of `.left`/`.right`, and `.natural` text alignment instead of `.left`.

## Themes

- In SwiftUI, use `@EnvironmentObject private var theme: Theme` and inject `.environmentObject(Theme.sharedTheme)` where the view is used. Get colors with `AppTheme.color(for: .primaryText01, theme: theme)`.
- Theme colors come from `scripts/themes/theme.csv`: edit it and run `make generate_colors`. The generated `podcasts/ThemeColor.swift` and `ThemeStyle.swift` are gitignored, so Grep can't find tokens like `primaryText01`; never edit them by hand.

## Protocol Buffers

To regenerate after API changes:

```bash
brew install protobuf swift-protobuf  # One-time setup
make update_proto API_PATH=/path/to/pocketcasts-api/api/modules/protobuf/src/main/proto
```
