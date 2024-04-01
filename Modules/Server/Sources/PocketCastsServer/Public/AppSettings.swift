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

extension AppSettings {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let defaults = AppSettings()

        try decode(\.$openLinks, forKey: .openLinks, fromContainer: container, withDefaults: defaults)
        try decode(\.$rowAction, forKey: .rowAction, fromContainer: container, withDefaults: defaults)
        try decode(\.$episodeGrouping, forKey: .episodeGrouping, fromContainer: container, withDefaults: defaults)
        try decode(\.$showArchived, forKey: .showArchived, fromContainer: container, withDefaults: defaults)
        try decode(\.$upNextSwipe, forKey: .upNextSwipe, fromContainer: container, withDefaults: defaults)
        try decode(\.$skipForward, forKey: .skipForward, fromContainer: container, withDefaults: defaults)
        try decode(\.$skipBack, forKey: .skipBack, fromContainer: container, withDefaults: defaults)
        try decode(\.$keepScreenAwake, forKey: .keepScreenAwake, fromContainer: container, withDefaults: defaults)
        try decode(\.$openPlayer, forKey: .openPlayer, fromContainer: container, withDefaults: defaults)
        try decode(\.$intelligentResumption, forKey: .intelligentResumption, fromContainer: container, withDefaults: defaults)
        try decode(\.$playUpNextOnTap, forKey: .playUpNextOnTap, fromContainer: container, withDefaults: defaults)
        try decode(\.$playbackActions, forKey: .playbackActions, fromContainer: container, withDefaults: defaults)
        try decode(\.$legacyBluetooth, forKey: .legacyBluetooth, fromContainer: container, withDefaults: defaults)
        try decode(\.$multiSelectGesture, forKey: .multiSelectGesture, fromContainer: container, withDefaults: defaults)
        try decode(\.$chapterTitles, forKey: .chapterTitles, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoPlayEnabled, forKey: .autoPlayEnabled, fromContainer: container, withDefaults: defaults)
        try decode(\.$notifications, forKey: .notifications, fromContainer: container, withDefaults: defaults)
        try decode(\.$appBadge, forKey: .appBadge, fromContainer: container, withDefaults: defaults)
        try decode(\.$appBadgeFilter, forKey: .appBadgeFilter, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchivePlayed, forKey: .autoArchivePlayed, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchiveInactive, forKey: .autoArchiveInactive, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchiveIncludesStarred, forKey: .autoArchiveIncludesStarred, fromContainer: container, withDefaults: defaults)
        try decode(\.$volumeBoost, forKey: .volumeBoost, fromContainer: container, withDefaults: defaults)
        try decode(\.$trimSilence, forKey: .trimSilence, fromContainer: container, withDefaults: defaults)
        try decode(\.$playbackSpeed, forKey: .playbackSpeed, fromContainer: container, withDefaults: defaults)
        try decode(\.$playerBookmarksSortType, forKey: .playerBookmarksSortType, fromContainer: container, withDefaults: defaults)
        try decode(\.$episodeBookmarksSortType, forKey: .episodeBookmarksSortType, fromContainer: container, withDefaults: defaults)
        try decode(\.$podcastBookmarksSortType, forKey: .podcastBookmarksSortType, fromContainer: container, withDefaults: defaults)
        try decode(\.$profileBookmarksSortType, forKey: .profileBookmarksSortType, fromContainer: container, withDefaults: defaults)
        try decode(\.$filesAutoUpNext, forKey: .filesAutoUpNext, fromContainer: container, withDefaults: defaults)
        try decode(\.$filesAfterPlayingDeleteLocal, forKey: .filesAfterPlayingDeleteLocal, fromContainer: container, withDefaults: defaults)
        try decode(\.$filesAfterPlayingDeleteCloud, forKey: .filesAfterPlayingDeleteCloud, fromContainer: container, withDefaults: defaults)
        try decode(\.$warnDataUsage, forKey: .warnDataUsage, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoUpNextLimit, forKey: .autoUpNextLimit, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoUpNextLimitReached, forKey: .autoUpNextLimitReached, fromContainer: container, withDefaults: defaults)
        try decode(\.$headphoneControlsNextAction, forKey: .headphoneControlsNextAction, fromContainer: container, withDefaults: defaults)
        try decode(\.$headphoneControlsPreviousAction, forKey: .headphoneControlsPreviousAction, fromContainer: container, withDefaults: defaults)
        try decode(\.$privacyAnalytics, forKey: .privacyAnalytics, fromContainer: container, withDefaults: defaults)
        try decode(\.$marketingOptIn, forKey: .marketingOptIn, fromContainer: container, withDefaults: defaults)
        try decode(\.$freeGiftAcknowledgement, forKey: .freeGiftAcknowledgement, fromContainer: container, withDefaults: defaults)
        try decode(\.$gridOrder, forKey: .gridOrder, fromContainer: container, withDefaults: defaults)
        try decode(\.$gridLayout, forKey: .gridLayout, fromContainer: container, withDefaults: defaults)
        try decode(\.$badges, forKey: .badges, fromContainer: container, withDefaults: defaults)
        try decode(\.$filesSortOrder, forKey: .filesSortOrder, fromContainer: container, withDefaults: defaults)
        try decode(\.$playerShelf, forKey: .playerShelf, fromContainer: container, withDefaults: defaults)
        try decode(\.$useSystemTheme, forKey: .useSystemTheme, fromContainer: container, withDefaults: defaults)
        try decode(\.$theme, forKey: .theme, fromContainer: container, withDefaults: defaults)
        try decode(\.$lightThemePreference, forKey: .lightThemePreference, fromContainer: container, withDefaults: defaults)
        try decode(\.$darkThemePreference, forKey: .darkThemePreference, fromContainer: container, withDefaults: defaults)
        try decode(\.$useEmbeddedArtwork, forKey: .useEmbeddedArtwork, fromContainer: container, withDefaults: defaults)
        try decode(\.$useDarkUpNextTheme, forKey: .useDarkUpNextTheme, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoPlayLastListUuid, forKey: .autoPlayLastListUuid, fromContainer: container, withDefaults: defaults)
    }

    private mutating func decode<Value: Codable & Equatable>(
        _ keyPath: WritableKeyPath<Self, ModifiedDate<Value>>,
        forKey key: CodingKeys,
        fromContainer container: KeyedDecodingContainer<CodingKeys>,
        withDefaults defaults: Self
    ) throws {
        self[keyPath: keyPath] = try container.decodeIfPresent(ModifiedDate<Value>.self, forKey: key) ?? defaults[keyPath: keyPath]
    }
}

extension SettingsStore<AppSettings> {
    public static internal(set) var appSettings = SettingsStore(key: "app_settings", value: AppSettings())
}
