import Foundation

public protocol PCDatabase {
    var changes: Int32 { get }

    func pragmaUserVersion() -> Int32?

    func executeQuery(_ sql: String, values: [Any]?) throws -> PCDBResultSet

    func executeUpdate(_ sql: String, values: [Any]?) throws

    @discardableResult
    func commit() -> Bool

    @discardableResult
    func beginTransaction() -> Bool

    func insert(into: String, columns: [String], values: [Any?]) throws

    func lastErrorCode() -> Int32

    func lastErrorMessage() -> String

    @discardableResult
    func rollback() -> Bool
}
