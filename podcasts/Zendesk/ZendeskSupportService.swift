import Combine
import Foundation
import PocketCastsUtils

class ZendeskSupportService {
    enum SupportRequestError: Error {
        case serverError(statusCode: Int, bodyExcerpt: String?)
        case badRequest
        case noInternetConnection
        case invalidResponse
    }

    private let session: URLSession
    private let config: ZDConfig

    private static let responseExcerptCharacterLimit = 256

    private struct ZendeskErrorResponse: Decodable {
        let error: String?
        let description: String?
        let details: [String: [ZendeskErrorDetail]]?

        private enum CodingKeys: String, CodingKey {
            case error
            case description
            case details
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            error = try? container.decode(String.self, forKey: .error)
            description = try? container.decode(String.self, forKey: .description)
            details = try? container.decode([String: [ZendeskErrorDetail]].self, forKey: .details)
        }
    }

    private struct ZendeskErrorDetail: Codable {
        let type: String?
        let description: String?
    }

    init(config: ZDConfig, session: URLSession = URLSession.shared) {
        self.session = session
        self.config = config
    }

    func submitSupportRequest(_ supportRequest: ZDSupportRequest, isRetrying: Bool = false) -> AnyPublisher<String, Error> {
        let request: URLRequest
        do {
            request = try generateSupportRequest(supportRequest, isRetrying: isRetrying)
        } catch {
            FileLog.shared.addMessage("ZendeskSupportService: failed to build request (isRetrying: \(isRetrying)): \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }

        let urlLabel = isRetrying ? "newBaseURL" : "baseURL"
        let requestURL = request.url?.absoluteString ?? "<nil>"
        FileLog.shared.addMessage("ZendeskSupportService: POST \(requestURL) (\(urlLabel))")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — non-HTTP response")
                    throw SupportRequestError.invalidResponse
                }

                let status = httpResponse.statusCode
                guard 200 ..< 300 ~= status else {
                    let bodyExcerpt = Self.responseBodyExcerpt(from: data)
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — HTTP \(status), body: \(bodyExcerpt ?? "<empty>")")
                    throw SupportRequestError.serverError(statusCode: status, bodyExcerpt: bodyExcerpt)
                }

                FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit succeeded — HTTP \(status)")
                return ""
            }
            .mapError { error -> Error in
                if let supportError = error as? SupportRequestError {
                    return supportError
                }
                if let urlError = error as? URLError {
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — URLError \(urlError.code.rawValue) \(urlError.localizedDescription)")
                    if urlError.code == .notConnectedToInternet {
                        return SupportRequestError.noInternetConnection
                    }
                } else {
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — \(error)")
                }
                return error
            }
            .eraseToAnyPublisher()
    }

    private static func responseBodyExcerpt(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        guard let response = try? JSONDecoder().decode(ZendeskErrorResponse.self, from: data)
        else {
            return "<non-JSON response omitted>"
        }

        var fields = [String]()
        if let error = response.error {
            fields.append("error: \(error)")
        }
        if let description = response.description {
            fields.append("description: \(description)")
        }
        if let details = response.details {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            if let data = try? encoder.encode(details) {
                fields.append("details: \(String(decoding: data, as: UTF8.self))")
            }
        }

        guard !fields.isEmpty else {
            return "<unrecognized JSON response omitted>"
        }

        return sanitizedExcerpt(fields.joined(separator: ", "))
    }

    private static func sanitizedExcerpt(_ value: String) -> String {
        let withoutControlCharacters = value.unicodeScalars
            .map { CharacterSet.controlCharacters.contains($0) ? " " : String($0) }
            .joined()
        let redacted = withoutControlCharacters.replacingOccurrences(
            of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            with: "<redacted-email>",
            options: [.regularExpression, .caseInsensitive]
        )
        let singleLine = redacted.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return String(singleLine.prefix(responseExcerptCharacterLimit))
    }

    private func generateSupportRequest(_ supportRequest: ZDSupportRequest, isRetrying: Bool = false) throws -> URLRequest {
        guard let url = config.url(for: .requests, newURL: isRetrying),
              let authToken = config.authToken(forEmail: supportRequest.requester.email)
        else { throw SupportRequestError.badRequest }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(ZDSupportRequestWrapper(request: supportRequest))

        return request
    }
}
