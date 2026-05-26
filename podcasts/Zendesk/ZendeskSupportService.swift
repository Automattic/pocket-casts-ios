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
                    let bodyExcerpt = String(data: data.prefix(256), encoding: .utf8)
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — HTTP \(status), body: \(bodyExcerpt ?? "<non-utf8>")")
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
                } else {
                    FileLog.shared.addMessage("ZendeskSupportService: \(urlLabel) submit failed — \(error)")
                }
                return error
            }
            .eraseToAnyPublisher()
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
