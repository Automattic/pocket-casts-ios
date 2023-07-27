import Foundation

extension L10n {
    // MARK: Proper Nouns

    /// These strings are proper nouns and shouldn't be localized
    static let appleWatch = "Apple Watch"
    static let pocketCasts = "Pocket Casts"
    static let pocketCastsShort = "Casts"
    static let twitter = "Twitter"
    static let instagram = "Instagram"
    static let socialHandle = "@pocketcasts"
    static let websiteShort = "pocketcasts.com"

    // MARK: Support

    /// These items are intentionally left un-localized to help enforce the expectation that we only provide support in English at this time.
    ///

    /* Support request screen title for opening a request for support (instead of providing feedback) */
    static let support = "Support"

    /// When localizing  this text should be transitioned to use `L10n.cancel`
    static let supportCancel = "Cancel"

    /* Persistent prompt on the support request screen for the user to enter a description about their request */
    static let supportCommentIndicator = "Description:"

    /* Persistent prompt on the support request screen for the user to enter their email */
    static let supportEmailIndicator = "Email:"

    /* Placeholder in the email text box */
    static let supportEmailPlaceholder = "Enter your email"

    /* Error message for when the support request fails to process. */
    static let supportErrorMsg = "Please try again later or you can reach out directly by emailing us at 'support@pocketcasts.com'"

    /* Error title for when the support request fails to process. */
    static let supportErrorTitle = "Oops something went wrong"

    /* Support request screen title for opening a request that suggests a new feature (instead of asking for support) */
    static let supportFeedback = "Feedback"

    /* Privacy toggle to indicate if the user is ok with the inclusion of debug logs. */
    static let supportIncludeDebugInformation = "Include Debug Information:"

    /* Title for the display field that shows the attached debug logs */
    static let supportLogsDebug = "Debug Logs:"

    /* Title for the display field that shows the attached meta data */
    static let supportLogsMetaData = "Meta Data:"

    /// When localizing  this text should be transitioned to use `L10n.podcastsPlural + ":"`
    static let supportLogsPodcasts = "Podcasts:"

    /* Title for the display field that shows the attached tags */
    static let supportLogsTags = "Tags:"

    /* Title for the display field that shows the attached wearable logs */
    static let supportLogsWearable = "Watch Logs:"

    /* Persistent prompt on the support request screen for the user to enter their name */
    static let supportNameIndicator = "Name:"

    /* Placeholder in the name text box */
    static let supportNamePlaceholder = "Enter your name"

    /// When localizing  this text should be transitioned to use `L10n.ok`
    static let supportOK = "Ok"

    /* Prompt to submit a service request. */
    static let supportSubmit = "Submit"

    /* Confirmation title on the support request screen thanking them for submitting their request */
    static let supportThankyou = "Thank you!"

    /* Confirmation message on the support request screen letting them know that responses will be sent to their email. */
    static let supportThankyouMessage = "Keep an eye on your email, and we'll get back to you as soon as possible."

    /* Title for the screen that displays the attached logs */
    static let supportTitleAttachedLogs = "Attached Logs"

    /* Activity message letting the user know that a process ir running. */
    static let supportWorking = "Working..."

    // MARK: Helper Functions

    static func podcastCount(_ count: Int, capitalized: Bool = false) -> String {
        let result = count == 1 ? L10n.podcastCountSingular : L10n.podcastCountPluralFormat(count.localized())
        return capitalized ? result.localizedCapitalized : result
    }

    static func downloadedFilesConf(_ count: Int) -> String {
        count == 1 ? L10n.downloadedFilesConfSingular : L10n.downloadedFilesConfPluralFormat(count.localized())
    }

    static func selectedPodcastCount(_ count: Int, capitalized: Bool = false) -> String {
        let result: String
        if count == 0 {
            result = L10n.settingsAutoDownloadsNoPodcastsSelected
        } else if count == 1 {
            result = L10n.settingsAutoDownloadsPodcastsSelectedSingular
        } else {
            result = L10n.settingsAutoDownloadsPodcastsSelectedFormat(count.localized())
        }

        return capitalized ? result.localizedCapitalized : result
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
    static func localizedFormat(_ key: String, _ table: String?) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)

        if format.isEmpty || format == key {
            // The key hasn't been translated yet so return the english translation
            return BundleToken.baseBundle.localizedString(forKey: key, value: nil, table: table)
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
        let path = Bundle.main.path(forResource: "en", ofType: "lproj")
        return Bundle(path: path!)!
    }()
}
