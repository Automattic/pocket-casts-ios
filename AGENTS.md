## Formatting

Format all code using the linter formatter:
```bash
make format
```

## Building and Running

```bash
make build_staging
```

## Cleaning Build Artifacts

```bash
make clean
```

## Running Tests

```bash
make test_staging
```

### Running a Single Test

```bash
make test_staging ONLY_TESTING=PocketCastsTests/YourTestClass/testMethodName
```

### Running Module Tests

```bash
# DataModel module tests
make test_staging ONLY_TESTING=PocketCastsDataModelTests

# Server module tests
make test_staging ONLY_TESTING=PocketCastsServerTests

# Utils module tests
make test_staging ONLY_TESTING=PocketCastsUtilsTests
```

## Architecture

### Modular Structure

The codebase uses Swift Package Manager modules under `Modules/`:

- **DataModel** (`Modules/DataModel/`) - Core data persistence using GRDB. Contains podcast, episode, and playback models. Uses custom GRDB macros for model generation.
- **Server** (`Modules/Server/`) - API communication layer using Protocol Buffers. Depends on DataModel and Utils.
- **Utils** (`Modules/Utils/`) - Shared utilities including localization helpers.
- **DependencyInjection** (`Modules/DependencyInjection/`) - DI container for the app.

### Main App Structure

The main iOS app lives in `podcasts/` with:
- UIKit + SwiftUI hybrid (123+ ViewControllers, XIBs/Storyboards)
- Feature-based organization (Analytics, Bookmarks, Folders, IAP, Player, etc.)
- Multi-platform targets: iOS, watchOS, widgets, App Clip, CarPlay

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `podcasts/` | Main iOS app source |
| `PocketCastsTests/` | Unit tests organized by feature |
| `Pocket Casts Watch App/` | watchOS companion |
| `WidgetExtension/` | Home screen widgets |
| `BuildTools/` | SwiftLint and SwiftGen plugins |

## Data Access - DataManager (Singleton Facade)

All data operations go through `DataManager.sharedManager`:

```swift
// Located at: Modules/DataModel/Sources/PocketCastsDataModel/Public/DataManager.swift
let dataManager = DataManager.sharedManager

// Podcast operations
let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
let podcast = dataManager.findPodcast(uuid: "...")
dataManager.save(podcast: podcast)

// Episode operations
let episode = dataManager.findEpisode(uuid: "...")
dataManager.save(episode: episode)
let downloadedCount = dataManager.downloadedEpisodeCount()

// Playlist/Filter operations
let playlists = dataManager.allPlaylists(includeDeleted: false)
let episodes = dataManager.playlistEpisodes(for: playlist)

// Up Next queue
let queue = dataManager.allUpNextEpisodes()

// Folder operations
let folders = dataManager.allFolders(includeDeleted: false)
let podcastsInFolder = dataManager.allPodcastsInFolder(folder: folder)
```

## Localization

Strings are managed via SwiftGen. Add new strings to `podcasts/en.lproj/Localizable.strings`:

```swift
/* Description for translators with placeholder info */
"feature_description_key" = "Value with %1$@ placeholder";
```

Use generated `L10n` enum:
```swift
let text = L10n.featureDescriptionKey(value)
```

Key rules:
- Use snake_case keys with pattern: `feature_relevantIdentifier_description`
- Always include comment describing context and placeholders
- Use positional specifiers (`%1$@`, `%2$@`), never string interpolation
- Handle plurals manually with separate `_singular`/`_plural` keys

## Code Style

SwiftLint is configured with opt-in rules. Notable custom rules:
- Use `naturalContentHorizontalAlignment` instead of `.left`/`.right` for RTL support
- Use `.natural` text alignment instead of `.left`
- Never use `LocalizedStringKey` in SwiftUI - use `NSLocalizedString` with L10n

## Themes
- When styling Views, use `@EnvironmentObject private var theme: Theme` and inject `.environmentObject(Theme.sharedTheme)` where the View is used.
- Use `AppTheme.color(for: .primaryText01, theme: theme)` to access themed colors

## Protocol Buffers

Server objects use protobuf. To regenerate after API changes:
```bash
brew install protobuf swift-protobuf  # One-time setup
make update_proto API_PATH=/path/to/pocketcasts-api/api/modules/protobuf/src/main/proto
```
