import Foundation
import PocketCastsUtils

@propertyWrapper
/// Stores a Codable value in UserDefaults,. The `Settings` type provides the User Defaults for writing to so it can be overridden globally.
public struct CodableStore<Value: JSONCodable, Settings: SettingsStore<Value>> {
    let key: String
    let defaultValue: Value

    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }

    init(wrappedValue: Value, _ key: String) {

        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript(
        _enclosingInstance instance: Settings,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Settings, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Settings, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            return (try? container.jsonObject(Value.self, forKey: key)) ?? defaultValue
        }
        set {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            container.setJSONObject(newValue, forKey: key)
        }
    }
}
