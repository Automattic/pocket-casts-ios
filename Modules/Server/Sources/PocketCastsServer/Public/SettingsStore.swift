import Foundation
import PocketCastsUtils

/// A storage type for a `Codable` settings value.
/// This handles storage to `UserDefaults` (optionally overridable)
@dynamicMemberLookup
public final class SettingsStore<Value: JSONCodable> {
    public let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard, key: String, value: Value) {
        self.userDefaults = userDefaults
        _settings = CodableStore(wrappedValue: value, key)
    }

    @CodableStore var settings: Value

    /// Access any property from `settings` without direct access to settings.
    /// Avoids having to type `appSettings.settings` and allows for future ObservableObject / publisher adoption in this method
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get {
            settings[keyPath: keyPath]
        }
        set {
            settings[keyPath: keyPath] = newValue
        }
    }
}
