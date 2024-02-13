import Foundation

@propertyWrapper
/// Adds a `modifiedAt` date to any property and adds encode/decode logic.
public struct ModifiedDate<Value: Codable & Equatable>: Equatable, Codable {
    var value: Value
    public private(set) var modifiedAt: Date?

    public init(wrappedValue: Value) {
        self.value = wrappedValue
        self.modifiedAt = nil
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
