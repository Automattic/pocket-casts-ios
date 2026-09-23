import Foundation
enum DBUtils {
    static func convertDate(value: TimeInterval?) -> Date? {
        guard let value, value > 0 else { return nil }

        return Date(timeIntervalSince1970: value)
    }

    static func nullIfNil(value: Any?) -> Any {
        guard let value else { return NSNull() }

        return value
    }

    static func valuesQuestionMarks(amount: Int) -> String {
        if amount == 0 { return "" }
        if amount == 1 { return "(?)" }

        let questionMarks = String(repeating: ",? ", count: amount - 1)

        return "(?\(questionMarks))"
    }

    static func nonNilStringFromColumn(resultSet rs: PCDBResultSet, columnName: String) -> String {
        if let value = rs.string(forColumn: columnName) {
            return value
        }

        return ""
    }

    static func replaceNilWithNull(value: Any?) -> Any {
        value == nil ? NSNull() : value!
    }

    static func currentUTCTimeInMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    static func generateUniqueId() -> Int64 {
        var urandom: UInt64 = 0
        if SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt64>.size, &urandom) != 0 {
            arc4random_stir()
            urandom = (UInt64(arc4random()) << 32) | UInt64(arc4random())
        }

        let random = Int64(urandom & 0x7FFF_FFFF_FFFF_FFFF)

        return random
    }

    static func measureTime(_ action: () -> ()) -> TimeInterval {
        let startDate = Date()
        action()
        let endDate = Date()
        return startDate.distance(to: endDate)
    }
}

// MARK: - DB Array Extension

extension Array where Element == Any? {
    /// Converts any nil items in the array to an NSNull
    var databaseValues: [Any] {
        map { $0 ?? NSNull() }
    }

    /// Converts an array to VALUES (?, ...) for each of the items for use in an INSERT query
    var insertBindingValues: String {
        "VALUES (\(map { _ in "?" }.columnString))"
    }
}

extension Array where Element == String {
    /// Helper that returns a string joined by , for use in a db queries
    var columnString: String {
        joined(separator: ",")
    }
}
