import PocketCastsUtils

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {
    @ModifiedDate public var openLinks: Bool

    @ModifiedDate public var rowAction: PrimaryRowAction

    static var defaults: AppSettings {
        return AppSettings(openLinks: true, rowAction: .download)
    }
}

extension SettingsStore<AppSettings> {
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings.defaults)
}
