import Foundation

/// A dotted numeric version, such as an app's `7.43` or a release's `7.43.1`.
///
/// Versions are compared component by component rather than as text, so `7.10` is newer than `7.9`
/// rather than older, and a version is padded with zeros against a longer one, so `7.43` and
/// `7.43.0` are the same version.
public struct Version: Hashable, Comparable, LosslessStringConvertible, Sendable {
    /// The version's components, most significant first, without the trailing zeros that don't
    /// change which version it is.
    public let components: [Int]

    /// Parses a dotted numeric version, returning `nil` for anything that isn't one.
    ///
    /// Anything but digits and the dots between them is rejected rather than guessed at, leaving it
    /// to the caller to decide what an unparsable version should mean.
    public init?(_ description: String) {
        var components: [Int] = []
        for component in description.split(separator: ".", omittingEmptySubsequences: false) {
            guard component.allSatisfy({ $0.isASCII && $0.isNumber }), let value = Int(component) else { return nil }
            components.append(value)
        }

        guard !components.isEmpty else { return nil }

        while components.count > 1, components.last == 0 {
            components.removeLast()
        }
        self.components = components
    }

    public var description: String {
        components.map(String.init).joined(separator: ".")
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        for index in 0 ..< max(lhs.components.count, rhs.components.count) {
            let left = lhs.components[safe: index] ?? 0
            let right = rhs.components[safe: index] ?? 0
            if left != right { return left < right }
        }
        return false
    }
}
