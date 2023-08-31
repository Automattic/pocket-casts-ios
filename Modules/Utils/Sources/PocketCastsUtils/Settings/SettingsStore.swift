import Foundation

// MARK: - SettingsStore

public protocol SettingsStore {
    /// Retrieves the value for the specified key
    func value<Value>(for key: String) -> Value?
}

// MARK: - WritableSettingsStore
public protocol WritableSettingsStore: SettingsStore {
    /// Stores the value for the given key
    func save<Value>(value: Value, for key: String)

    /// Deletes the value for given key
    func removeValue(for key: String)
}
