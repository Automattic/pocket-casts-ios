import PocketCastsUtils
import PocketCastsDataModel

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {

    // MARK: General
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

    // MARK: Playback Effects

    @ModifiedDate public var volumeBoost: Bool
    @ModifiedDate public var trimSilence: TrimSilenceAmount
    @ModifiedDate public var playbackSpeed: Double

    @ModifiedDate public var warnDataUsage: Bool = false

    @ModifiedDate public var autoUpNextLimit: Int32 = 100
    @ModifiedDate public var autoUpNextLimitReached: AutoAddLimitReachedAction = .stopAdding

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
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
