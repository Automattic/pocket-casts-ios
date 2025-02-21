import Foundation

protocol PCDatabase {
    var changes: Int32 { get }

    func executeQuery(_ sql: String, values: [Any]?) throws -> PCDBResultSet

    func executeUpdate(_ sql: String, values: [Any]?) throws

    func commit()

    func beginTransaction()

    func insert(into: String, columns: [String], values: [Any?]) throws

    func lastErrorCode() -> Int32

    func lastErrorMessage() -> String

    func rollback()
}
