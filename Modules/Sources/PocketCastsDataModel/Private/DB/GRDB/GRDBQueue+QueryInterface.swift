import Foundation
import GRDB
import PocketCastsUtils

/// Extension to GRDBQueue providing direct access to GRDB's `Database` inside a write,
/// for callers that need GRDB APIs rather than the `PCDatabase` abstraction.
extension GRDBQueue {
    /// Execute a write block with direct GRDB Database access
    /// - Parameter block: Block that receives a GRDB Database instance
    /// - Returns: True if successful
    @discardableResult
    func write(_ block: (Database) throws -> Void) -> Bool {
        do {
            try dbPool.write(block)
            return true
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }

    /// Execute a write block with direct GRDB Database access and return a value
    /// - Parameter block: Block that receives a GRDB Database instance and returns a value
    /// - Returns: The value returned by the block, or nil on error
    func write<T>(_ block: (Database) throws -> T) -> T? {
        do {
            return try dbPool.write(block)
        } catch {
            logger?.log(error: error, context: [:])
            return nil
        }
    }
}
