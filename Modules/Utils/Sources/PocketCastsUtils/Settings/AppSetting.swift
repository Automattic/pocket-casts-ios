import Foundation

// MARK: - AppSetting

open class AppSetting<Value>: Setting<Value, UserDefaults>, WritableSetting {
    public typealias SetValueTransformer = ((Value) -> Any?)
    public typealias GetValueTransformer = ((Any?) -> Value?)

    private let setValue: SetValueTransformer?
    private let getValue: GetValueTransformer?
    private let modifiedKey: String

    public init(_ key: String = #function,
                modifiedKey: String? = nil,
                defaultValue: Value,
                setValue: SetValueTransformer? = nil,
                getValue: GetValueTransformer? = nil,
                store: UserDefaults = .standard) {
        self.modifiedKey = modifiedKey ?? "\(key)_modified"
        self.setValue = setValue
        self.getValue = getValue

        super.init(key, defaultValue: defaultValue, store: store)
    }

    public override var value: Value {
        get {
            let transformedValue = getValue?(store.object(forKey: key))
            let value = transformedValue ?? store.value(for: key)

            return value ?? defaultValue
        }

        set {
            save(newValue)
        }
    }

    public func save(_ value: Value, updateModified: Bool = true) {
        if let setValue {
            store.setValue(setValue(value), forKey: key)
        } else {
            store.save(value: value, for: key)
        }

        if updateModified {
            store.save(value: Date(), for: modifiedKey)
        }

        objectWillChange.send()
    }

    /// Deletes the setting from the store
    public func remove() {
        store.removeValue(for: key)
        store.removeValue(for: modifiedKey)
        objectWillChange.send()
    }

    /// Resets the value back to the `defaultValue`
    public func reset() {
        save(defaultValue)
    }
}
