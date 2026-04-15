import Foundation

public extension Array {
    /// - Returns: The array value or nil if the array is empty
    func nilIfEmpty() -> [Element]? {
        isEmpty ? nil : self
    }
}
