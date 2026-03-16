import Foundation

public protocol PCDBResultSet {
    func close()

    func next() -> Bool

    func int(forColumnIndex: Int32) -> Int32

    func int(forColumn: String) -> Int32

    func long(forColumn: String) -> Int

    func long(forColumnIndex: Int32) -> Int

    func object(forColumn: String) -> Any?

    func string(forColumn: String) -> String?

    func longLongInt(forColumn: String) -> Int64

    func bool(forColumn: String) -> Bool

    func double(forColumn: String) -> Double

    func date(forColumn: String) -> Date?
}
