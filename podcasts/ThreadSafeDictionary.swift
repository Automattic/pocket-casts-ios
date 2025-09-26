import PocketCastsUtils

class ThreadSafeDictionary<Key: Hashable, Value> {

    private let queue: DispatchQueue
    private var table: [Key: Value] = [:]

    init(label: String = "au.com.shiftyjelly.podcasts.SyncHashTable") {
        queue = DispatchQueue(label: label, attributes: .concurrent)
    }

    deinit {
        //ensure that all work is done before releasing the table
        queue.async(flags: .barrier) { [table] in
            //Last work item
            FileLog.shared.console("Dealocating table with \(table.count) elements")
        }
    }

    func value(forKey key: Key) -> Value? {
        var value: Value?
        queue.sync { [weak self] in
            value = self?.table[key]
        }
        return value
    }

    func updateValue(_ value: Value?, forKey key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            self?.table[key] = value
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

    func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.table.removeAll()
        }
    }

    func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        var result = false
        try queue.sync { [weak self] in
            result = try self?.table.contains(where: predicate) ?? false
        }
        return result
    }
}
