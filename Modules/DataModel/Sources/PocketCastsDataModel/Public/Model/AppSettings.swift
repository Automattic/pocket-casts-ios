import PocketCastsUtils
import MetaCodable

/// Model type for synced & stored App Settings
@Codable
@MemberInit
public struct AppSettings: JSONCodable {

    // MARK: - General
    @Default(false)
    @ModifiedDate public var openLinks: Bool

    @Default(PrimaryRowAction.stream)
    @ModifiedDate public var rowAction: PrimaryRowAction

    @Default(PodcastGrouping.none)
    @ModifiedDate public var episodeGrouping: PodcastGrouping
    @Default(false)
    @ModifiedDate public var showArchived: Bool
    @Default(PrimaryUpNextSwipeAction.playNext)
    @ModifiedDate public var upNextSwipe: PrimaryUpNextSwipeAction

    @Default(45)
    @ModifiedDate public var skipForward: Int32
    @Default(10)
    @ModifiedDate public var skipBack: Int32

    @Default(false)
    @ModifiedDate public var keepScreenAwake: Bool
    @Default(false)
    @ModifiedDate public var openPlayer: Bool
    @Default(true)
    @ModifiedDate public var intelligentResumption: Bool

    @Default(false)
    @ModifiedDate public var playUpNextOnTap: Bool
    @Default(false)
    @ModifiedDate public var playbackActions: Bool
    @Default(false)
    @ModifiedDate public var legacyBluetooth: Bool
    @Default(true)
    @ModifiedDate public var multiSelectGesture: Bool
    @Default(true)
    @ModifiedDate public var chapterTitles: Bool
    @Default(true)
    @ModifiedDate public var autoPlayEnabled: Bool

    @Default(false)
    @ModifiedDate public var notifications: Bool

    @Default(AppBadge.off)
    @ModifiedDate public var appBadge: AppBadge
    @Default("")
    @ModifiedDate public var appBadgeFilter: String

    @Default(AutoArchiveAfterPlayed.afterPlaying)
    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed
    @Default(AutoArchiveAfterInactive.never)
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive
    @Default(false)
    @ModifiedDate public var autoArchiveIncludesStarred: Bool

    // MARK: Playback Effects

    @Default(false)
    @ModifiedDate public var volumeBoost: Bool
    @Default(TrimSilence.off)
    @ModifiedDate public var trimSilence: TrimSilence
    @Default(1)
    @ModifiedDate public var playbackSpeed: Double

    @Default(BookmarksSort.newestToOldest)
    @ModifiedDate public var playerBookmarksSortType: BookmarksSort
    @Default(BookmarksSort.newestToOldest)
    @ModifiedDate public var episodeBookmarksSortType: BookmarksSort
    @Default(BookmarksSort.newestToOldest)
    @ModifiedDate public var podcastBookmarksSortType: BookmarksSort
    @Default(BookmarksSort.newestToOldest)
    @ModifiedDate public var profileBookmarksSortType: BookmarksSort

    @Default(false)
    @ModifiedDate public var filesAutoUpNext: Bool
    @Default(false)
    @ModifiedDate public var filesAfterPlayingDeleteLocal: Bool
    @Default(false)
    @ModifiedDate public var filesAfterPlayingDeleteCloud: Bool

    @Default(false)
    @ModifiedDate public var warnDataUsage: Bool

    @Default(100)
    @ModifiedDate public var autoUpNextLimit: Int32
    @Default(AutoAddLimitReachedAction.stopAdding)
    @ModifiedDate public var autoUpNextLimitReached: AutoAddLimitReachedAction

    @Default(HeadphoneControl.skipForward)
    @ModifiedDate public var headphoneControlsNextAction: HeadphoneControl
    @Default(HeadphoneControl.skipBack)
    @ModifiedDate public var headphoneControlsPreviousAction: HeadphoneControl

    @Default(true)
    @ModifiedDate public var privacyAnalytics: Bool
    @Default(false)
    @ModifiedDate public var marketingOptIn: Bool
    @Default(false)
    @ModifiedDate public var freeGiftAcknowledgement: Bool

    @Default(LibrarySort.dateAddedNewestToOldest)
    @ModifiedDate public var gridOrder: LibrarySort
    @Default(LibraryType.threeByThree)
    @ModifiedDate public var gridLayout: LibraryType = .threeByThree
    @Default(BadgeType.off)
    @ModifiedDate public var badges: BadgeType

    @Default(UploadedSort.newestToOldest)
    @ModifiedDate public var filesSortOrder: UploadedSort

    @Default([ActionOption]())
    @ModifiedDate public var playerShelf: [ActionOption]

    // MARK: - Appearance

    @Default(true)
    @ModifiedDate public var useSystemTheme: Bool
    @Default(ThemeType.light)
    @ModifiedDate public var theme: ThemeType
    @Default(ThemeType.light)
    @ModifiedDate public var lightThemePreference: ThemeType
    @Default(ThemeType.dark)
    @ModifiedDate public var darkThemePreference: ThemeType

    @Default(false)
    @ModifiedDate public var useEmbeddedArtwork: Bool

    @Default(true)
    @ModifiedDate public var useDarkUpNextTheme: Bool
    @Default(AutoPlaySource.uuid(""))
    @ModifiedDate public var autoPlayLastListUuid: AutoPlaySource
}

extension SettingsStore<AppSettings> {
    public static internal(set) var appSettings = SettingsStore(key: "app_settings", value: AppSettings())
}
