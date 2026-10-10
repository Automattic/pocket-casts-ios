import os

/// A lock that protects a value, with the same call-site API as `Synchronization.Mutex`.
///
/// `Synchronization.Mutex` requires iOS 18 and watchOS 11. Once the deployment targets reach that,
/// delete this type and `import Synchronization` instead.
public struct Mutex<Value>: ~Copyable {
    @usableFromInline
    let lock: OSAllocatedUnfairLock<Value>

    public init(_ initialValue: Value) {
        lock = OSAllocatedUnfairLock(uncheckedState: initialValue)
    }

    /// Calls `body` with exclusive access to the protected value and returns its result.
    @inlinable
    public borrowing func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        try lock.withLockUnchecked(body)
    }
}

extension Mutex: @unchecked Sendable where Value: Sendable {}

extension Mutex where Value: Sendable {
    /// The protected value. The getter and setter each take the lock separately, so use `withLock`
    /// to read and modify the value in one step.
    @inlinable
    public var value: Value {
        get { withLock { $0 } }
        nonmutating set { withLock { $0 = newValue } }
    }
}
