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
                           multiSelectGesture: true
        )
    }
}

extension SettingsStore<AppSettings> {
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
