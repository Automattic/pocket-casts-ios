import PocketCastsUtils

/// Model type for synced & stored App Settings
public struct AppSettings: JSONCodable {
    @ModifiedDate public var openLinks: Bool = false

    @ModifiedDate public var rowAction: PrimaryRowAction = .download

    public init() {
    }
}

extension SettingsStore<AppSettings> {
    public static let appSettings = SettingsStore(key: "app_settings", value: AppSettings())
}
