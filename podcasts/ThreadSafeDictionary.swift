import Foundation

class ThreadSafeDictionary<Key: Hashable, Value> {

    private let tableLock = NSLock()
    private var table: [Key: Value] = [:]

    func value(forKey key: Key) -> Value? {
        tableLock.lock()
        defer { tableLock.unlock() }
        return table[key]
    }

    func updateValue(_ value: Value?, forKey key: Key) {
        tableLock.lock()
        defer { tableLock.unlock() }
        table[key] = value
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
        tableLock.lock()
        defer { tableLock.unlock() }
        table.removeAll()
    }

    func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        tableLock.lock()
        defer { tableLock.unlock() }
        return try table.contains(where: predicate)
    }
}
