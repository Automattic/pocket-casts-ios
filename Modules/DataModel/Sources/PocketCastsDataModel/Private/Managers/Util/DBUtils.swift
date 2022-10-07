import FMDB

class DBUtils {
    class func convertDate(value: TimeInterval?) -> Date? {
        guard let value = value, value > 0 else { return nil }

        return Date(timeIntervalSince1970: value)
    }

    class func nullIfNil(value: Any?) -> Any {
        guard let value = value else { return NSNull() }

        return value
    }

    class func valuesQuestionMarks(amount: Int) -> String {
        if amount == 0 { return "" }
        if amount == 1 { return "(?)" }

        let questionMarks = String(repeating: ",? ", count: amount - 1)

        return "(?\(questionMarks))"
    }

    class func nonNilStringFromColumn(resultSet rs: FMResultSet, columnName: String) -> String {
        if let value = rs.string(forColumn: columnName) {
            return value
        }

        return ""
    }

    class func replaceNilWithNull(value: Any?) -> Any {
        value == nil ? NSNull() : value!
    }

    class func currentUTCTimeInMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    class func generateUniqueId() -> Int64 {
        var urandom: UInt64 = 0
        if SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt64>.size, &urandom) != 0 {
            arc4random_stir()
            urandom = (UInt64(arc4random()) << 32) | UInt64(arc4random())
        }

        let random = Int64(urandom & 0x7FFF_FFFF_FFFF_FFFF)

        return random
    }
}
