import Foundation
import PocketCastsUtils

extension L10n {
    // MARK: Proper Nouns

    /// These strings are proper nouns and shouldn't be localized
    static let appleWatch = "Apple Watch"
    static let pocketCasts = "Pocket Casts"
    static let pocketCastsShort = "Casts"
    static let xCom = "X"
    static let instagram = "Instagram"
    static let bluesky = "Bluesky"
    static let socialHandle = "@pocketcasts"
    static let blueskyHandle = "@pocketcasts.com"
    static let websiteShort = "pocketcasts.com"

    // MARK: Support

    /// These items are intentionally left un-localized to help enforce the expectation that we only provide support in English at this time.
    ///

    /* Subject label for a support request (instead of providing feedback) */
    static let support = "Support"

    /* Subject label for a request that suggests a new feature (instead of asking for support) */
    static let supportFeedback = "Feedback"

    /* Line in the support email body, below the space for the customer's message and above the device details. */
    static let supportEmailDetailsPrompt = "Please write your message above this line. The details below help our team look into your request."

    /* Activity message shown while the support email and its logs are prepared. */
    static let supportPreparingEmail = "Preparing email..."

    /* Title of the alert shown when no email app can open the support email. */
    static let supportNoEmailAppTitle = "No email app found"

    /* Message of the alert shown when no email app can open the support email. The parameter is the support email address. */
    static func supportNoEmailAppMessage(_ address: String) -> String {
        "Please email us at \(address) from any email app."
    }

    /* Button that copies the support email address. */
    static let supportCopyEmailAddress = "Copy Email Address"

    /// When localizing  this text should be transitioned to use `L10n.ok`
    static let supportOK = "Ok"

    /* Prompt to submit a service request. */
    static let supportSubmit = "Submit"

    // MARK: Helper Functions

    static func podcastCount(_ count: Int, capitalized: Bool = false) -> String {
        let result = count == 1 ? L10n.podcastCountSingular : L10n.podcastCountPluralFormat(count.localized())
        return capitalized ? result.localizedCapitalized : result
    }

    static func playlistEpisodeCount(_ count: Int) -> String {
        count == 1 ? L10n.podcastEpisodeCountSingular : L10n.playlistEpisodesCount(count)
    }

    static func downloadedFilesConf(_ count: Int) -> String {
        count == 1 ? L10n.downloadedFilesConfSingular : L10n.downloadedFilesConfPluralFormat(count.localized())
    }

    static func selectedPodcastCount(_ count: Int) -> String {
        if count == 0 {
            return L10n.settingsAutoDownloadsNoPodcastsSelected
        } else if count == 1 {
            return L10n.settingsAutoDownloadsPodcastsSelectedSingular
        } else {
            return L10n.settingsAutoDownloadsPodcastsSelectedFormat(count.localized())
        }
    }

    static func timeShorthand(_ time: Int) -> String {
        let value = Double(time)
        if value < 60 {
            let components = DateComponents(calendar: .current, second: Int(value))
            return DateComponentsFormatter.localizedString(from: components, unitsStyle: .short) ?? L10n.timePlaceholder
        } else {
            let components = DateComponents(calendar: .current, minute: Int(floor(value / 60.0)), second: Int(value) % 60)
            return DateComponentsFormatter.localizedString(from: components, unitsStyle: .abbreviated) ?? L10n.timePlaceholder
        }
    }

    static func downloadCountPrompt(_ count: Int) -> String {
        count == 1 ? L10n.downloadEpisodeSingular : L10n.downloadEpisodePluralFormat(count.localized())
    }

    static let bulkDownloadMax: String = {
        #if os(watchOS)
            return L10n.bulkDownloadMaxFormat(100.localized())
        #else
            return L10n.bulkDownloadMaxFormat(Constants.Limits.maxBulkDownloads.localized())
        #endif
    }()

    static func seasonEpisodeShorthand(seasonNumber: Int64, episodeNumber: Int64, shortFormat: Bool = false) -> String {
        if seasonNumber > 0, episodeNumber > 0 {
            return L10n.seasonEpisodeShorthandFormat(seasonNumber.localized(), episodeNumber.localized())
        } else if seasonNumber > 0, episodeNumber == 0 {
            return L10n.seasonOnlyShorthandFormat(seasonNumber.localized())
        } else if shortFormat {
            return L10n.episodeShorthandFormatShort(episodeNumber.localized())
        } else {
            return L10n.episodeShorthandFormat(episodeNumber.localized())
        }
    }

    /// `1 bookmark` or `N bookmarks`
    static func bookmarkCount(_ count: Int) -> String {
        count == 1 ? L10n.bookmarksCountSingular : L10n.bookmarksCountPlural(count)
    }
}

extension L10n {
    static func localizedFormat(_ key: String, _ table: String?, _ value: String? = nil) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)

        if format.isEmpty || format == key {
            // The key hasn't been translated yet so return the english translation
            return BundleToken.baseBundle.localizedString(forKey: key, value: value, table: table)
        }

        return format
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: BundleToken.self)
        #endif
    }()

    static let baseBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }()
}
