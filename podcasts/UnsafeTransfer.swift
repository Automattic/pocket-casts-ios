/// Borrowed from swift-nio
/// https://github.com/apple/swift-nio/blob/263642512098086d981c864a870560d2405f65ea/Sources/NIOCore/NIOSendable.swift#L31-L46

/// ``UnsafeTransfer`` can be used to make non-`Sendable` values `Sendable`.
/// As the name implies, the usage of this is unsafe because it disables the sendable checking of the compiler.
/// It can be used similar to `@unsafe Sendable` but for values instead of types.
@usableFromInline
struct UnsafeTransfer<Wrapped> {
    @usableFromInline
    var wrappedValue: Wrapped

    @inlinable
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
extension UnsafeTransfer: @unchecked Sendable {}
#endif

extension UnsafeTransfer: Equatable where Wrapped: Equatable {}
extension UnsafeTransfer: Hashable where Wrapped: Hashable {}
