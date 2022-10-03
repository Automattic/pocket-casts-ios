import Foundation

struct ErrorResponse: Decodable {
    var message: String?
    var errorMessage: String?
    var success: Bool?

    func userMessage() -> String? {
        message ?? errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case errorMessage, message, success
    }
}
