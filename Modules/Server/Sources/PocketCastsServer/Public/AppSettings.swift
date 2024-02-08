import PocketCastsUtils
import PocketCastsDataModel

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {

    // MARK: General
    @ModifiedDate public var openLinks: Bool

    @ModifiedDate public var rowAction: PrimaryRowAction


    @ModifiedDate public var skipForward: Int32
    @ModifiedDate public var skipBack: Int32

    @ModifiedDate public var keepScreenAwake: Bool
    @ModifiedDate public var openPlayer: Bool

    static var defaults: AppSettings {
        return AppSettings(openLinks: false,
                           rowAction: .stream,
                           skipForward: 45,
                           skipBack: 10,
                           keepScreenAwake: false,
                           openPlayer: false
        )
    }
}

extension SettingsStore<AppSettings> {
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
