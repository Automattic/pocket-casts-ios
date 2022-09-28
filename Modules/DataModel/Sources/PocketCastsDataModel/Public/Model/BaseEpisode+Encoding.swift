import Foundation

public extension BaseEpisode {
    func encode(date: Date?) -> String {
        guard let date = date else { return "" }

        return "\(date.timeIntervalSince1970)"
    }

    func decodeInt32FromString(value: String?) -> Int32 {
        guard let value = value, value.count > 0 else { return 0 }

        return Int32(value) ?? 0
    }

    func decodeInt64FromString(value: String?) -> Int64 {
        guard let value = value, value.count > 0 else { return 0 }

        return Int64(value) ?? 0
    }

    func decodeDateFromString(date: String?) -> Date? {
        guard let date = date, date.count > 0, let doubleVal = Double(date) else { return nil }

        return Date(timeIntervalSince1970: doubleVal)
    }

    func decodeBoolFromString(value: String?) -> Bool {
        guard let value = value else { return false }

        return Bool(value) ?? false
    }

    func decodeDoubleFromString(value: String?) -> Double {
        guard let value = value else { return 0 }

        return Double(value) ?? 0
    }

    func decodeOptionalStringFromString(value: String?) -> String? {
        guard let value = value, value.count > 0 else { return nil }

        return value
    }
}
