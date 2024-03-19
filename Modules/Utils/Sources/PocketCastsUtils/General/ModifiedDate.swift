import Foundation

@propertyWrapper
/// Adds a `modifiedAt` date to any property and adds encode/decode logic.
public struct ModifiedDate<Value: Codable & Equatable>: Equatable, Codable {
    var value: Value
    public private(set) var modifiedAt: Date?

    public init(wrappedValue: Value, modifiedAt: Date? = nil) {
        self.value = wrappedValue
        self.modifiedAt = modifiedAt
    }

    public var wrappedValue: Value {
        get { value }
        set {
            if value != newValue {
                modifiedAt = Date()
            }
            value = newValue
        }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
}

extension ModifiedDate {

    /// This is a property wrapper which handles converting Integer value.
    /// "the SQL datatype of the result is NULL for a JSON null, INTEGER or REAL for a JSON numeric value, an INTEGER zero for a JSON false value, an INTEGER one for a JSON true value"
    /// See more details on the `json_extract` output here: https://www.sqlite.org/json1.html#jex
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        do {
            value = try container.decode(Value.self, forKey: .value)
        } catch let error {
            // Add additional decoding for Int -> Bool due to SQLite type issues
            // "the SQL datatype of the result is NULL for a JSON null, INTEGER or REAL for a JSON numeric value, an INTEGER zero for a JSON false value, an INTEGER one for a JSON true value"
            // See more details on the `json_extract` output here: https://www.sqlite.org/json1.html#jex
            if let intValue = try? container.decode(Int.self, forKey: .value), let val = Bool(int: intValue) as? Value {
                value = val
            } else {
                throw error
            }
        }

        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt)
    }
}

fileprivate extension Bool {
    init?(int: Int) {
        switch int {
        case 0:
            self = false
        case 1:
            self = true
        default:
            return nil
        }
    }
}
