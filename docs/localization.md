# Localization

The app uses [SwiftGen](https://github.com/SwiftGen/SwiftGen) to create the app strings from the `Localizable.strings` files in the app. To add a new string add it to the English translation of the [Localizable.strings](../podcasts/en.lproj/Localizable.strings) file. 

On each build any new string added to the english localization of `Localizable.strings` will created a generated constant or function in [Strings+Generated.swift](../podcasts/Strings+Generated.swift) as part of the `L10n` enum.

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

The localization for swift packages currently exists in the host app ([DataModel+Strings](../podcasts/DataModel+Strings.swift), [Server+Strings](../podcasts/Server+Strings.swift)). As much as possible, try to keep localization to the host app, this simplifies the release process. If a string can't be defined in the host app you can reference it via the main bundle such as in the DataModel [Strings+L10n](../Modules/DataModel/Sources/DataModel/Private/Strings+L10n.swift)
