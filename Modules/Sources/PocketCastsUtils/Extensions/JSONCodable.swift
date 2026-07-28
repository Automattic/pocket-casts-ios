import Foundation

/**
 This provides some protocols to reduce the boilerplate of encoding and decoding objects to/from JSON.
 JSONCodable is a typealias of the JSONEncodable and JSONDecodable protocols.

 ## JSONEncodable
 This inherits from the Encodable protocol and defines a `jsonData` property which
 by default will encode the object using a basic JSONEncoder() and will return nil on failure.

 ## JSONDecodable
 This inherits from the Decodable protocol and defines the `encodeObject(type:from)` method which by default will attempt
 to decode the given `data` to the specified `type` and will return nil if the decoding fails or can't be cast to the `type`.

 ## Example Usage:

 enum HelloWorldEnum: JSONCodable {
    case one, two, three
 }

 print(HelloWorldEnum.one.jsonData as? NSData)
    Outputs -> Optional(<7b226f6e 65223a7b 7d7d>) -> {"one":{}}

 struct HelloWorldStruct: JSONCodable {
     let one: String
     let two: HelloWorldEnum
 }

 print(HelloWorld(one: "one", two: .two).jsonData as? NSData)
    Outputs -> Optional(<7b227477 6f223a7b 2274776f 223a7b7d 7d2c226f 6e65223a 226f6e65 227d>) -> {"two":{"two":{}},"one":"one"}

 ## UserDefaults
 This also provides a UserDefaults extension that allows easy reading and writing of
 encoded values using `set(encodedValue:forKey)` and `jsonObject(type:forKey)`

 The methods behave similar to the default `set(value:forKey)` and `object(forKey:)` methods.
 */

// MARK: - JSONEncodable

/// A type that can encode itself as JSON data using a JSONEncoder
public protocol JSONEncodable: Encodable {
    /// Returns a Data representation of the JSON value
    var jsonData: Data? { get }
}

public extension JSONEncodable {
    var jsonData: Data? {
        try? JSONEncoder().encode(self)
    }
}

// MARK: - JSONDecodable

/// A type that can decode itself from a JSON Data representation using JSONDecoder.
public protocol JSONDecodable: Decodable {
    /// Decodes the data using the given type and returns the value on success or nil on failure.
    static func encodedObject<Value: JSONDecodable>(_ type: Value.Type, from data: Data) throws -> Value
}

public extension JSONDecodable {
    /// By default the value is decoded using a basic JSONDecoder and will return nil if decoding fails or is not the correct type.
    static func encodedObject<Value: JSONDecodable>(_ type: Value.Type, from data: Data) throws -> Value {
        try JSONDecoder().decode(Value.self, from: data)
    }
}

// MARK: - JSONCodable
public typealias JSONCodable = JSONDecodable & JSONEncodable

// MARK: - UserDefaults + JSONCodable
public extension UserDefaults {
    /// Saves a JSONEncodable object to the UserDefaults for the given key.
    /// Passing nil to this will delete the value.
    func setJSONObject(_ encodedValue: JSONEncodable?, forKey key: String) {
        set(encodedValue?.jsonData, forKey: key)
    }

    /// Retrieves the JSONDecodable object from the UserDefaults for the given key.
    /// THe value and cast it to the given `type`
    func jsonObject<Value: JSONDecodable>(_ type: Value.Type, forKey: String) throws -> Value? {
        try data(forKey: forKey).flatMap {
            try Value.encodedObject(type, from: $0)
        }
    }
}
