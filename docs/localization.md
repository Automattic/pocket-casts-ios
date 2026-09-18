# Localization

The app uses [SwiftGen](https://github.com/SwiftGen/SwiftGen) to create the app strings from the `Localizable.strings` files in the app. To add a new string add it to the English translation of the [Localizable.strings](../podcasts/en.lproj/Localizable.strings) file. 

On each build any new string added to the english localization of `Localizable.strings` will created a generated constant or function in the `L10n` enum. The enum lives in the `PocketCastsLocalization` module ([Modules/Sources/PocketCastsLocalization](../Modules/Sources/PocketCastsLocalization)); its `GenerateL10n` build plugin runs SwiftGen whenever the English strings change. The app targets re-export the module from [Exports.swift](../podcasts/Exports.swift), so app code uses `L10n` without an import.

When Strings are generated, they are converted from snake case to camel case and strings with an associated format are created as functions that will accept the passed in parameters and perform a type checking.

During the release process, the `en.lproj/Localizable.strings` file is then uploaded to [GlotPress](https://translate.wordpress.com/projects/pocket-casts/ios/) for translation. Before the release build is finalized, all the translations are grabbed from GlotPress and saved back to the `Localizable.strings` files.

## Use Snake Cased Keys

When adding strings add then with meaningful keys that describe `feature_` + `relevantIdentifier(s)_` + `description`. GlotPress will truncate strings over 255 characters which can cause issues with detecting changes.

```swift
// Do
"settings_auto_add_limit_subtitle_stop" = "New episodes will stop being added when Up Next reaches %1$@ episodes.";
```

```swift
// Avoid
"New episodes will stop being added when Up Next reaches %1$@ episodes." = "New episodes will stop being added when Up Next reaches %1$@ episodes.";
```

Try to keep the `Localizable.strings` file alphabetized to help detect collisions.

## Always add Comments

Always add a meaningful comment. If possible, describe where and how the string will be used. If there are placeholders, describe what each placeholder is. 

```swift
// Do
/* Format used to show the Season and the Episode number of a podcast. '%1$@' is a placeholder for the season number.'%2$@' is a placeholder for the episode number. */
"season_episode_format" = "Season %1$@ Episode %2$@";
```

```swift
// Avoid
"title" = "Podcast %@"
```

Comments help give more context to translators.

## Do not use Interpolated Strings

Interpolated strings are harder to understand by translators and they may end up translating/changing the variable name, causing a crash.

Use positional specifiers such as %1$@ instead.

```swift
// Do

// Localizable String
"season_episode_shorthand_format" = "S%1$@ E%2$@";

/// --- /// 

let str = L10n.seasonEpisodeShorthandFormat(season, episode)
```

```swift
// Don't
let year = 2019
let str = NSLocalizedString("© \(year) Acme, Inc.", comment: "Copyright Notice")
```

## Pluralization

GlotPress currently does not support pluralization using the [`.stringsdict` file](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html#//apple_ref/doc/uid/10000171i-CH5-SW10). So, right now, you have to support plurals manually by having separate localized strings.

```swift
// Localizable Strings

"podcasts_plural" = "Podcasts";
"podcast_singular" = "Podcast";

/// --- ///

let label = count == 1 ? L10n.podcastSingular : L10n.podcastsPlural
```

## Numbers

Localize numbers whenever possible. Numbers often vary based on their delimiters so make sure you account for that in strings. There are [helper functions](../Modules/Utils/Sources/Utils/Formatting/LocalizationHelpers.swift) to localize many base formats.

```swift
let localizedCount = NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)
- or -

let localizedCount = count.localized(.none)

```


## Swift Packages

The translations stay in the host app's `Localizable.strings` files, which each target bundles; `L10n` reads them from the main bundle. A module that needs strings depends on `PocketCastsLocalization` and imports it. In module unit tests, where the main bundle has no translations, `L10n` returns the English values.
