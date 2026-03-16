import GRDB
import Foundation

class GRDBResultSet: PCDBResultSet {
    private let rowCursor: RowCursor
    private var row: Row!

    private var closed = false

    init(rowCursor: RowCursor) {
        self.rowCursor = rowCursor
    }

    func close() {
        closed = true
    }

    func next() -> Bool {
        if closed {
            fatalError("Result set is closed")
        }

        try? row = rowCursor.next()
        return row != nil
    }

    func int(forColumnIndex: Int32) -> Int32 {
        guard let valueForColumn = Array(row.databaseValues)[safe: Int(forColumnIndex)], let int32Value = Int32.fromDatabaseValue(valueForColumn) else {
            return 0
        }

        return int32Value
    }

    func int(forColumn: String) -> Int32 {
        row[forColumn]
    }

    func long(forColumn: String) -> Int {
        row[forColumn]
    }

    func long(forColumnIndex: Int32) -> Int {
        guard let valueForColumn = Array(row.databaseValues)[safe: Int(forColumnIndex)], let intValue = Int.fromDatabaseValue(valueForColumn) else {
            return 0
        }

        return intValue
    }

    func object(forColumn: String) -> Any? {
        row[forColumn]
    }

    func string(forColumn: String) -> String? {
        row[forColumn]
    }

    func longLongInt(forColumn: String) -> Int64 {
        row[forColumn] ?? 0
    }

    func bool(forColumn: String) -> Bool {
        row[forColumn] ?? false
    }

    func double(forColumn: String) -> Double {
        // GRDB sometimes convert the date right away to a String
        // When casting back to double, it becomes the year, which mess up
        // the date. We deal with this special case here
        if row[forColumn] is String {
            return Date.fromDatabaseValue(row[forColumn])?.timeIntervalSince1970 ?? 0
        }

        return row[forColumn] ?? 0
    }

    func date(forColumn: String) -> Date? {
        row[forColumn]
    }
}
