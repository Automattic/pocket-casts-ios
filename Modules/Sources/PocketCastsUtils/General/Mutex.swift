import os

/// A lock that protects a value, with the same API as `Synchronization.Mutex`.
///
/// `Synchronization.Mutex` requires iOS 18 and watchOS 11. Once the deployment targets reach that,
/// delete this type and `import Synchronization` instead.
public struct Mutex<Value>: ~Copyable {
    @usableFromInline
    let lock: OSAllocatedUnfairLock<Value>

    public init(_ initialValue: consuming sending Value) {
        lock = OSAllocatedUnfairLock(uncheckedState: initialValue)
    }

    /// Calls `body` with exclusive access to the protected value and returns its result.
    @inlinable
    public borrowing func withLock<Result, E: Error>(_ body: (inout sending Value) throws(E) -> sending Result) throws(E) -> sending Result {
        let result = lock.withLockUnchecked { value in
            withUnsafeMutablePointer(to: &value) { pointer -> UnsafeTransfer<Swift.Result<Result, E>> in
                let pointer = UnsafeTransfer(pointer)
                do throws(E) {
                    return UnsafeTransfer(.success(try body(&pointer.wrappedValue.pointee)))
                } catch {
                    return UnsafeTransfer(.failure(error))
                }
            }
        }
        return try result.wrappedValue.get()
    }
}

extension Mutex: @unchecked Sendable {}
