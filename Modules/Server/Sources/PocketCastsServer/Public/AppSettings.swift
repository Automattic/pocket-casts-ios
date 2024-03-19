import PocketCastsUtils
import PocketCastsDataModel

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {

    // MARK: - General
    @ModifiedDate public var openLinks: Bool

    @ModifiedDate public var rowAction: PrimaryRowAction

    @ModifiedDate public var episodeGrouping: PodcastGrouping
    @ModifiedDate public var showArchived: Bool
    @ModifiedDate public var upNextSwipe: PrimaryUpNextSwipeAction

    @ModifiedDate public var skipForward: Int32
    @ModifiedDate public var skipBack: Int32

    @ModifiedDate public var keepScreenAwake: Bool
    @ModifiedDate public var openPlayer: Bool
    @ModifiedDate public var intelligentResumption: Bool

    @ModifiedDate public var playUpNextOnTap: Bool
    @ModifiedDate public var playbackActions: Bool
    @ModifiedDate public var legacyBluetooth: Bool
    @ModifiedDate public var multiSelectGesture: Bool
    @ModifiedDate public var chapterTitles: Bool
    @ModifiedDate public var autoPlayEnabled: Bool

    @ModifiedDate public var appBadge: AppBadge = .off
    @ModifiedDate public var appBadgeFilter: String = ""

    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed = .afterPlaying
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive = .never
    @ModifiedDate public var autoArchiveIncludesStarred: Bool = false

    // MARK: Playback Effects

    @ModifiedDate public var volumeBoost: Bool
    @ModifiedDate public var trimSilence: TrimSilenceAmount
    @ModifiedDate public var playbackSpeed: Double

    @ModifiedDate public var playerBookmarksSortType: BookmarksSort = .newestToOldest
    @ModifiedDate public var episodeBookmarksSortType: BookmarksSort = .newestToOldest
    @ModifiedDate public var podcastBookmarksSortType: BookmarksSort = .newestToOldest
    @ModifiedDate public var profileBookmarksSortType: BookmarksSort = .newestToOldest

    @ModifiedDate public var filesAutoUpNext: Bool = false
    @ModifiedDate public var filesAfterPlayingDeleteLocal: Bool = false
    @ModifiedDate public var filesAfterPlayingDeleteCloud: Bool = false

    @ModifiedDate public var warnDataUsage: Bool = false

    @ModifiedDate public var autoUpNextLimit: Int32 = 100
    @ModifiedDate public var autoUpNextLimitReached: AutoAddLimitReachedAction = .stopAdding

    @ModifiedDate public var headphoneControlsNextAction: HeadphoneControl = .skipForward
    @ModifiedDate public var headphoneControlsPreviousAction: HeadphoneControl = .skipBack

    @ModifiedDate public var privacyAnalytics: Bool = true
    @ModifiedDate public var marketingOptIn: Bool = false
    @ModifiedDate public var freeGiftAcknowledgement: Bool = false

    @ModifiedDate public var gridOrder: LibrarySort = .dateAddedNewestToOldest
    @ModifiedDate public var gridLayout: LibraryType = .fourByFour
    @ModifiedDate public var badges: BadgeType = .off

    @ModifiedDate public var filesSortOrder: UploadedSort = .newestToOldest

    @ModifiedDate public var playerShelf: [ActionOption] = []

    // MARK: - Appearance

    @ModifiedDate public var useSystemTheme: Bool = true
    @ModifiedDate public var theme: ThemeType = .light
    @ModifiedDate public var lightThemePreference: ThemeType = .light
    @ModifiedDate public var darkThemePreference: ThemeType = .dark

    @ModifiedDate public var useEmbeddedArtwork: Bool = false

    @ModifiedDate public var useDarkUpNextTheme: Bool = true
    @ModifiedDate public var autoPlayLastListUuid: AutoPlaySource = .uuid("")

    static var defaults: AppSettings {
        return AppSettings(openLinks: false,
                           rowAction: .stream,
                           episodeGrouping: .none,
                           showArchived: false,
                           upNextSwipe: .playNext,
                           skipForward: 45,
                           skipBack: 10,
                           keepScreenAwake: false,
                           openPlayer: false,
                           intelligentResumption: true,
                           playUpNextOnTap: false,
                           playbackActions: false,
                           legacyBluetooth: false,
                           multiSelectGesture: true,
                           chapterTitles: true,
                           autoPlayEnabled: true,
                           volumeBoost: false,
                           trimSilence: .off,
                           playbackSpeed: 0
        )
    }
}

extension SettingsStore<AppSettings> {
    public static internal(set) var appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
