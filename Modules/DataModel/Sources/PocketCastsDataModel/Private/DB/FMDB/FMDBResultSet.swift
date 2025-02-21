import Foundation
import FMDB

final class FMDBResultSet: PCDBResultSet {
    private let fmdbResultSet: FMResultSet

    init(fmdbResultSet: FMResultSet) {
        self.fmdbResultSet = fmdbResultSet
    }

    deinit {
        fmdbResultSet.close()
    }

    func close() {
        fmdbResultSet.close()
    }

    func next() -> Bool {
        fmdbResultSet.next()
    }

    func int(forColumnIndex index: Int32) -> Int32 {
        fmdbResultSet.int(forColumnIndex: index)
    }

    func int(forColumn column: String) -> Int32 {
        fmdbResultSet.int(forColumn: column)
    }

    func long(forColumn column: String) -> Int {
        Int(fmdbResultSet.long(forColumn: column))
    }

    func long(forColumnIndex index: Int32) -> Int {
        Int(fmdbResultSet.long(forColumnIndex: index))
    }

    func object(forColumn column: String) -> Any? {
        fmdbResultSet.object(forColumn: column)
    }

    func string(forColumn column: String) -> String? {
        fmdbResultSet.string(forColumn: column)
    }

    func longLongInt(forColumn column: String) -> Int64 {
        fmdbResultSet.longLongInt(forColumn: column)
    }

    func bool(forColumn column: String) -> Bool {
        fmdbResultSet.bool(forColumn: column)
    }

    func double(forColumn column: String) -> Double {
        fmdbResultSet.double(forColumn: column)
    }

    func date(forColumn column: String) -> Date? {
        fmdbResultSet.date(forColumn: column)
    }
}
