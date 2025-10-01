@testable import PocketCastsDataModel
import GRDB

struct SQLiteValidator {
    enum SQLiteError: Error {
        case failedNewTestDatabase
    }

    /// Validates a SQL statement by preparing it against a test database
    /// that has been initialized using DatabaseHelper.setup(queue:).
    static func validate(sql: String, values: [Any]? = nil) throws {
        // Create a fresh test database pool
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteError.failedNewTestDatabase
        }

        // Wrap in our queue abstraction and run schema/setup
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)

        // Attempt to prepare the SQL via our database layer
        var error: Error?
        queue.read { db in
            do {
                _ = try db.executeQuery(sql, values: values)
            } catch let inError {
                error = inError
            }
        }

        if let error {
            throw error
        }
    }
}
