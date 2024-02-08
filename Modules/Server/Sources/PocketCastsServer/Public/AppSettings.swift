import PocketCastsUtils

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {
    @ModifiedDate public var openLinks: Bool

    @ModifiedDate public var rowAction: PrimaryRowAction


    @ModifiedDate public var skipForward: Int32
    @ModifiedDate public var skipBack: Int32

    static var defaults: AppSettings {
        return AppSettings(openLinks: false,
                           rowAction: .stream,
                           skipForward: 45,
                           skipBack: 10
        )
    }
}

extension SettingsStore<AppSettings> {
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
