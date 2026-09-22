## Building and Testing

Use the `xcode` MCP server (`xcrun mcpbridge`) by default:

- Build with `BuildProject`, and read errors with `GetBuildLog`. `XcodeRefreshCodeIssuesInFile` gives one file's diagnostics without a full build.
- Find tests with `GetTestList`, then run them with `RunSomeTests` or `RunAllTests`. The `UnitTests` plan covers `PocketCastsTests` and the module test targets.
- `RunProject` and `DeviceInteraction*` launch and drive the app in the simulator, `RenderPreview` renders SwiftUI previews, and `DocumentationSearch` searches Apple docs.

The tools act on the workspace open in Xcode (`XcodeListWorkspaces`). Opening a new checkout, such as a git worktree, with `XcodeOpenWorkspace` needs the user's approval in the Xcode MCP menu-bar item.

Without the MCP:

```bash
make build_staging
make test_staging ONLY_TESTING=PocketCastsTests/YourTestClass/testMethodName
make test_staging ONLY_TESTING=PocketCastsDataModelTests  # or PocketCastsServerTests, PocketCastsUtilsTests, PocketCastsAnalyticsTests
```

## Formatting

In Claude Code, a hook (`.claude/hooks/swiftlint.sh`) autocorrects each edited Swift file and reports the violations it can't fix. Otherwise, run `make lint_changed` to lint the branch's changes, or `make format` to autocorrect. `make format` covers the whole repo, so it can also change unrelated files.

## Architecture

- `podcasts/`: the iOS app, a UIKit and SwiftUI hybrid with XIBs and storyboards, organized by feature. CarPlay lives in `podcasts/CarPlay/`.
- Other targets: `Pocket Casts Watch App/`, `Pocket Casts TV App/`, `Pocket Casts App Clip/`, `WidgetExtension/`, `Share Extension/`.
- `PocketCastsTests/`: app unit tests.
- `BuildTools/`: pins the SwiftLint and SwiftGen versions.
- `Modules/Package.swift`: a single Swift package, with targets in `Modules/Sources/` and tests in `Modules/Tests/`:
  - **PocketCastsDataModel**: GRDB persistence. All data access goes through `DataManager.sharedManager` (`Public/DataManager.swift`).
  - **PocketCastsServer**: the API client, using Protocol Buffers.
  - **PocketCastsUtils**: shared utilities.
  - **PocketCastsAnalytics**: `Analytics`, the Tracks and logging adapters, and the A/B test provider. Add new events to `AnalyticsEvent.swift`.
  - **EndOfYear**: End of Year stories.
  - **XcodeSupport**: per-Xcode-target libraries that pull in each app target's package dependencies.

## Localization

Add strings to `podcasts/en.lproj/Localizable.strings`. The build regenerates the SwiftGen `L10n` enum, used as `L10n.featureDescriptionKey(value)`.

```
/* Context for translators, including what each placeholder is */
"feature_relevantIdentifier_description" = "Value with %1$@ placeholder";
```

- Use positional specifiers (`%1$@`, `%2$@`), never string interpolation.
- Handle plurals with separate `_singular` and `_plural` keys.
- Never use `LocalizedStringKey` in SwiftUI. Use `L10n` instead.

## Code Style

For RTL support, use `.natural` text alignment and `naturalContentHorizontalAlignment` instead of `.left`/`.right`. Custom SwiftLint rules enforce this.

## Themes

- In SwiftUI, use `@EnvironmentObject private var theme: Theme`, inject `.environmentObject(Theme.sharedTheme)` where the view is used, and read colors with `AppTheme.color(for: .primaryText01, theme: theme)`.
- `ThemeColor.swift` and `ThemeStyle.swift` are generated. Edit `scripts/themes/theme.csv`, then run `make generate_colors`.

## Protocol Buffers

After API changes, regenerate the server objects (the script installs `protobuf` and `swift-protobuf` with Homebrew):

```bash
make update_proto API_PATH=/path/to/pocketcasts-api/api/modules/protobuf/src/main/proto
```
