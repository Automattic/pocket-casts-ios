import Foundation

/// Parses ISO 8601 dates exactly like a default `ISO8601DateFormatter`, with a fast path for `yyyy-MM-dd'T'HH:mm:ss'Z'`,
/// the format the podcast cache server uses. Safe to call from any thread.
public enum ISO8601DateParser {
    private static let formatter = ISO8601DateFormatter()

    public static func date(from string: String) -> Date? {
        fastDate(from: string) ?? formatter.date(from: string)
    }

    /// Returns `nil` for anything other than a valid `yyyy-MM-dd'T'HH:mm:ss'Z'` date from 1583 onwards,
    /// since `ISO8601DateFormatter` switches to the Julian calendar before October 1582.
    static func fastDate(from string: String) -> Date? {
        var string = string
        return string.withUTF8 { bytes -> Date? in
            guard bytes.count == 20,
                  bytes[4] == UInt8(ascii: "-"), bytes[7] == UInt8(ascii: "-"), bytes[10] == UInt8(ascii: "T"),
                  bytes[13] == UInt8(ascii: ":"), bytes[16] == UInt8(ascii: ":"), bytes[19] == UInt8(ascii: "Z") else {
                return nil
            }

            func number(_ range: Range<Int>) -> Int? {
                var value = 0
                for index in range {
                    let digit = Int(bytes[index]) - 48
                    guard (0...9).contains(digit) else { return nil }
                    value = value * 10 + digit
                }
                return value
            }

            guard let year = number(0..<4), let month = number(5..<7), let day = number(8..<10),
                  let hour = number(11..<13), let minute = number(14..<16), let second = number(17..<19),
                  year >= 1583, (1...12).contains(month), hour < 24, minute < 60, second < 60 else {
                return nil
            }

            let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            let daysInMonth = month == 2 ? (isLeapYear ? 29 : 28) : ([4, 6, 9, 11].contains(month) ? 30 : 31)
            guard (1...daysInMonth).contains(day) else { return nil }

            let shiftedYear = month <= 2 ? year - 1 : year
            let era = shiftedYear / 400
            let yearOfEra = shiftedYear - era * 400
            let dayOfYear = (153 * ((month + 9) % 12) + 2) / 5 + day - 1
            let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
            let days = era * 146_097 + dayOfEra - 719_468

            return Date(timeIntervalSince1970: TimeInterval(((days * 24 + hour) * 60 + minute) * 60 + second))
        }
    }
}
