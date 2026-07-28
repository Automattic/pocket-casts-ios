import Foundation
import GRDB
import PocketCastsUtils

/// Extension to GRDBQueue providing GRDB QueryInterface support for type-safe queries.
/// These methods allow using GRDB's strongly-typed query building instead of raw SQL strings.
extension GRDBQueue {

    // MARK: - Read Operations

    /// Fetch all records of a given type
    /// - Parameter type: The record type to fetch
    /// - Returns: Array of fetched records
    func fetchAll<T: FetchableRecord & TableRecord>(_ type: T.Type) -> [T] {
        do {
            return try dbPool.read { db in
                try T.fetchAll(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return []
        }
    }

    /// Fetch all records matching a request
    /// - Parameter request: The query request
    /// - Returns: Array of fetched records
    func fetchAll<T: FetchableRecord>(_ request: some FetchRequest<T>) -> [T] {
        do {
            return try dbPool.read { db in
                try request.fetchAll(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return []
        }
    }

    /// Fetch one record matching a request
    /// - Parameter request: The query request
    /// - Returns: The fetched record or nil
    func fetchOne<T: FetchableRecord>(_ request: some FetchRequest<T>) -> T? {
        do {
            return try dbPool.read { db in
                try request.fetchOne(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return nil
        }
    }

    /// Fetch a record by primary key
    /// - Parameters:
    ///   - type: The record type to fetch
    ///   - key: The primary key value
    /// - Returns: The fetched record or nil
    func fetchOne<T: FetchableRecord & TableRecord>(_ type: T.Type, key: some DatabaseValueConvertible) -> T? {
        do {
            return try dbPool.read { db in
                try T.fetchOne(db, key: key)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return nil
        }
    }

    /// Execute a read block with direct GRDB Database access
    /// - Parameter block: Block that receives a GRDB Database instance and returns a value
    /// - Returns: The value returned by the block, or nil on error
    func read<T>(_ block: (Database) throws -> T) -> T? {
        do {
            return try dbPool.read(block)
        } catch {
            logger?.log(error: error, context: [:])
            return nil
        }
    }

    // MARK: - Write Operations

    /// Save a record (insert or update)
    /// - Parameter record: The record to save
    /// - Returns: True if successful
    @discardableResult
    func save<T: MutablePersistableRecord>(_ record: inout T) -> Bool {
        do {
            try dbPool.write { db in
                try record.save(db)
            }
            return true
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }

    /// Insert a record
    /// - Parameter record: The record to insert
    /// - Returns: True if successful
    @discardableResult
    func insert<T: MutablePersistableRecord>(_ record: inout T) -> Bool {
        do {
            try dbPool.write { db in
                try record.insert(db)
            }
            return true
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }

    /// Update a record
    /// - Parameter record: The record to update
    /// - Returns: True if successful
    @discardableResult
    func update<T: PersistableRecord>(_ record: T) -> Bool {
        do {
            try dbPool.write { db in
                try record.update(db)
            }
            return true
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }

    /// Delete a record
    /// - Parameter record: The record to delete
    /// - Returns: True if a record was deleted
    @discardableResult
    func delete<T: PersistableRecord>(_ record: T) -> Bool {
        do {
            return try dbPool.write { db in
                try record.delete(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }

    /// Delete all records matching a request
    /// - Parameter request: The query request for records to delete
    /// - Returns: Number of deleted records
    @discardableResult
    func deleteAll<T: TableRecord>(_ type: T.Type, filter: some SQLSpecificExpressible) -> Int {
        do {
            return try dbPool.write { db in
                try T.filter(filter).deleteAll(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return 0
        }
    }

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

    // MARK: - Count Operations

    /// Count all records of a given type
    /// - Parameter type: The record type to count
    /// - Returns: The count of records
    func count<T: TableRecord>(_ type: T.Type) -> Int {
        do {
            return try dbPool.read { db in
                try T.fetchCount(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return 0
        }
    }

    /// Count records matching a filter
    /// - Parameters:
    ///   - type: The record type to count
    ///   - filter: The filter expression
    /// - Returns: The count of matching records
    func count<T: TableRecord>(_ type: T.Type, filter: some SQLSpecificExpressible) -> Int {
        do {
            return try dbPool.read { db in
                try T.filter(filter).fetchCount(db)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return 0
        }
    }

    // MARK: - Batch Operations

    /// Update multiple records matching a filter
    /// - Parameters:
    ///   - type: The record type to update
    ///   - filter: The filter expression
    ///   - assignments: The column assignments
    /// - Returns: Number of updated records
    @discardableResult
    func updateAll<T: TableRecord>(_ type: T.Type, filter: some SQLSpecificExpressible, _ assignments: ColumnAssignment...) -> Int {
        do {
            return try dbPool.write { db in
                try T.filter(filter).updateAll(db, assignments)
            }
        } catch {
            logger?.log(error: error, context: [:])
            return 0
        }
    }

    /// Execute a batch of operations in a transaction
    /// - Parameter block: Block containing multiple database operations
    /// - Returns: True if all operations succeeded
    @discardableResult
    func inTransaction(_ block: (Database) throws -> Void) -> Bool {
        do {
            try dbPool.writeInTransaction { db in
                try block(db)
                return .commit
            }
            return true
        } catch {
            logger?.log(error: error, context: [:])
            return false
        }
    }
}
