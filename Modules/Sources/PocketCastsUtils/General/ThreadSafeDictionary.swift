import Foundation

public class ThreadSafeDictionary<Key: Hashable, Value> {

    private let tableLock = NSLock()
    private var table: [Key: Value] = [:]

    public init() {}

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

    public subscript(index: Key) -> Value? {
        get {
            return value(forKey: index)
        }
        set(newValue) {
            updateValue(newValue, forKey: index)
        }
    }

    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        tableLock.lock()
        defer { tableLock.unlock() }
        return table.removeValue(forKey: key)
    }

    public func removeAll() {
        tableLock.lock()
        defer { tableLock.unlock() }
        table.removeAll()
    }

    public func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        tableLock.lock()
        defer { tableLock.unlock() }
        return try table.contains(where: predicate)
    }
}
