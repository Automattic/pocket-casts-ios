import Foundation

// MARK: - mapFirst

/// `mapFirst` iterates over the sequence to find the first non-nil value as the result of the `transform`.
///  Before:
///
///     let coolData = [Cool(), Cool(), Cool(), ...]
///
///     for data in coolData {
///         if let value data.someValue {
///             return value
///         }
///     }
///
///  After:
///     coolData.mapFirst(where: { $0.someValue })
///
public extension Sequence {
    /// Finds the first non-`nil` transformed element in the sequence if available.
    /// - Parameter transform: A closure that accepts an element of this
    ///   sequence as its argument and returns an optional value.
    /// - Returns: The first non-`nil` result of `transform` or nil if there are none.
    func mapFirst<U>(where transform: (Element) throws -> U?) rethrows -> U? {
        for element in self {
            guard let result = try transform(element) else {
                continue
            }

            return result
        }

        return nil
    }
}
