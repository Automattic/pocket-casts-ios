import Foundation

// MARK: - Setting

open class Setting<Value, Store: SettingsStore> {
    public let key: String
    public let defaultValue: Value
    public let store: Store

    public init(_ key: String = #function, defaultValue: Value, store: Store) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    var value: Value {
        get {
            store.value(for: key) ?? defaultValue
        }
    }
}

/// Describes a Setting that can be updated
/// 
public protocol WritableSetting: ObservableObject {
    associatedtype Value

    var value: Value { get set }

    func save(_ value: Value, updateModified: Bool)
    func remove()
    func reset()
}
