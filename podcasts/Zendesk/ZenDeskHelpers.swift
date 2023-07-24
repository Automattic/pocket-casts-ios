import Combine
import Foundation

protocol ZDConfig {
    var apiKey: String { get }
    var baseURL: String { get }
    var newBaseURL: String { get }
    var subject: String { get }
    var isFeedback: Bool { get }
    var tags: [String] { get }

    func customFields(forDisplay: Bool, optOut: Bool) -> AnyPublisher<[ZDCustomField], Never>
}

extension ZDConfig {
    var tags: [String] {
        []
    }

    func customFields(forDisplay: Bool, optOut: Bool) -> AnyPublisher<[ZDCustomField], Never> {
        Result.Publisher([]).eraseToAnyPublisher()
    }

    func url(for request: ZenDeskAPI, newURL: Bool = false) -> URL? {
        URL(string: newURL ? newBaseURL : baseURL)?.appendingPathComponent(request.rawValue)
    }

    func authToken(forEmail email: String) -> String? {
        "\(email)/token:\(apiKey)".data(using: String.Encoding.utf8)?.base64EncodedString()
    }
}

enum ZenDeskAPI: String {
    case requests = "/api/v2/requests.json"
}

struct ZDSupportRequestWrapper: Codable {
    let request: ZDSupportRequest
}

struct ZDSupportRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case requester
        case subject
        case comment
        case customFields = "custom_fields"
        case tags
    }

    let requester: ZDRequester
    let subject: String
    let comment: ZDComment
    let customFields: [ZDCustomField]
    let tags: [String]

    init(subject: String, name: String, email: String, comment: String, customFields: [ZDCustomField] = [], tags: [String] = []) {
        requester = ZDRequester(name: name, email: email)
        self.comment = ZDComment(body: comment)
        self.subject = subject
        self.customFields = customFields
        self.tags = tags
    }
}

struct ZDCustomField: Codable {
    let id: Int
    let value: String
}

struct ZDRequester: Codable {
    let name: String
    let email: String
}

struct ZDComment: Codable {
    let body: String
}
