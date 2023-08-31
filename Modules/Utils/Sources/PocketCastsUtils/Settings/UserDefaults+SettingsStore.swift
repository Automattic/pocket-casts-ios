import Foundation

extension UserDefaults: WritableSettingsStore {
    public func value<Value>(for key: String) -> Value? {
        guard let decodableType = Value.self as? JSONDecodable.Type else {
            return object(forKey: key) as? Value
        }

        return jsonObject(decodableType.self, forKey: key) as? Value
    }

    public func save<Value>(value: Value, for key: String) {
        guard let decodableType = value as? JSONEncodable else {
            set(value, forKey: key)
            return
        }

        setJSONObject(decodableType, forKey: key)
    }

    public func removeValue(for key: String) {
        removeObject(forKey: key)
    }
}
