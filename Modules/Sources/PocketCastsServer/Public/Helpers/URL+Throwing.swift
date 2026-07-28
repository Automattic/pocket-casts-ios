import Foundation

// Creates a URL from a string by throw an exception if it fails
public extension URL {
    enum URLCreationError: Error {
        case invalidURLString
    }

    init(throwing string: String) throws {
        guard let url = URL(string: string) else {
            throw URLCreationError.invalidURLString
        }

        self = url
    }
}
