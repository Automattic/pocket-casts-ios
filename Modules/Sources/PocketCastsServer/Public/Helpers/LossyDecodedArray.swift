import Foundation

/// An array that drops the elements it can't decode instead of failing the whole payload.
///
/// A missing or `null` key decodes as an empty array.
@propertyWrapper
public struct LossyDecodedArray<Element: Decodable>: Decodable {
    public var wrappedValue: [Element]

    public init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode([DecodedElement].self).compactMap(\.element)
    }

    private struct DecodedElement: Decodable {
        let element: Element?

        init(from decoder: any Decoder) throws {
            element = try? decoder.singleValueContainer().decode(Element.self)
        }
    }
}

extension LossyDecodedArray: Equatable where Element: Equatable {}

extension LossyDecodedArray: Hashable where Element: Hashable {}

public extension KeyedDecodingContainer {
    func decode<Element>(_ type: LossyDecodedArray<Element>.Type, forKey key: Key) throws -> LossyDecodedArray<Element> {
        try decodeIfPresent(type, forKey: key) ?? LossyDecodedArray(wrappedValue: [])
    }
}
