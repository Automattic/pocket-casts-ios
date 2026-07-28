import Foundation

public class AtomicBool {
    private lazy var atomicQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.AtomicQueue")

        return queue
    }()

    private var storageValue = false

    public init() {}

    public init(_ initialValue: Bool) {
        storageValue = initialValue
    }

    public var value: Bool {
        get {
            atomicQueue.sync {
                storageValue
            }
        }
        set {
            atomicQueue.sync {
                storageValue = newValue
            }
        }
    }

    /// Atomically flips the value and returns the new value. Use this instead of
    /// `value.toggle()`, which performs a separate read and write and can race.
    @discardableResult
    public func toggle() -> Bool {
        atomicQueue.sync {
            storageValue.toggle()
            return storageValue
        }
    }
}
