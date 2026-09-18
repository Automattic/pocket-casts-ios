import os

/// A lock that protects a value, with the same API as `Synchronization.Mutex`.
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
    public borrowing func withLock<Result, E: Error>(_ body: (inout Value) throws(E) -> Result) throws(E) -> Result {
        let result = lock.withLockUnchecked { value -> Swift.Result<Result, E> in
            do throws(E) {
                return .success(try body(&value))
            } catch {
                return .failure(error)
            }
        }
        return try result.get()
    }
}

extension Mutex: @unchecked Sendable {}
