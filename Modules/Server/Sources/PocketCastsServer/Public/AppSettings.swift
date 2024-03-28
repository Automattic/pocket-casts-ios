import PocketCastsUtils
import PocketCastsDataModel

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {

    public static let defaults = AppSettings()

    // MARK: - General
    @ModifiedDate public var openLinks: Bool = false

    @ModifiedDate public var rowAction: PrimaryRowAction = .stream

    @ModifiedDate public var episodeGrouping: PodcastGrouping = .none
    @ModifiedDate public var showArchived: Bool = false
    @ModifiedDate public var upNextSwipe: PrimaryUpNextSwipeAction = .playNext

    @ModifiedDate public var skipForward: Int32 = 45
    @ModifiedDate public var skipBack: Int32 = 10

    @ModifiedDate public var keepScreenAwake: Bool = false
    @ModifiedDate public var openPlayer: Bool = false
    @ModifiedDate public var intelligentResumption: Bool = true

    @ModifiedDate public var playUpNextOnTap: Bool = false
    @ModifiedDate public var playbackActions: Bool = false
    @ModifiedDate public var legacyBluetooth: Bool = false
    @ModifiedDate public var multiSelectGesture: Bool = true
    @ModifiedDate public var chapterTitles: Bool = true
    @ModifiedDate public var autoPlayEnabled: Bool = true

    @ModifiedDate public var notifications: Bool = false

    @ModifiedDate public var appBadge: AppBadge = .off
    @ModifiedDate public var appBadgeFilter: String = ""

    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed = .afterPlaying
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive = .never
    @ModifiedDate public var autoArchiveIncludesStarred: Bool = false

    // MARK: Playback Effects

    @ModifiedDate public var volumeBoost: Bool = false
    @ModifiedDate public var trimSilence: TrimSilence = .off
    @ModifiedDate public var playbackSpeed: Double = 1

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
    @ModifiedDate public var gridLayout: LibraryType = .threeByThree
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
}

extension SettingsStore<AppSettings> {
    public static internal(set) var appSettings = SettingsStore(key: "app_settings", value: AppSettings())
}
