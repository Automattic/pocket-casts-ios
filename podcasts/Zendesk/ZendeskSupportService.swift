import Combine
import Foundation

class ZendeskSupportService {
    enum SupportRequestError: Error {
        case serverError
        case badRequest
        case noInternetConnection
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
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { _, response in
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    200 ..< 300 ~= httpResponse.statusCode
                else {
                    throw SupportRequestError.serverError
                }

                return ""
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
