class SyncHashTable<Key: Hashable, Value> {

    private let queue: DispatchQueue
    private var table: [Key: Value]

    init(label: String = "au.com.shiftyjelly.podcasts.SyncHashTable") {
        queue = DispatchQueue(label: label, attributes: .concurrent)
        table = [:]
    }

    func value(forKey key: Key) -> Value? {
        var value: Value?
        queue.sync {
            value = table[key]
        }
        return value
    }

    func updateValue(_ value: Value?, forKey key: Key) {
        queue.sync {
            table[key] = value
        }
    }

    subscript(index: Key) -> Value? {
        get {
            return value(forKey: index)
        }
        set(newValue) {
            updateValue(newValue, forKey: index)
        }
    }

    func removeValue(forKey key: Key) {
        updateValue(nil, forKey: key)
    }

    func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        var result = false
        try queue.sync {
            result = try table.contains(where: predicate)
        }
        return result
    }
}
