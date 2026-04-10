import Foundation

/// Swaps the current Authorization token with one for use with Sonos connections
class ExchangeSonosTask: ApiBaseTask {
    var completion: ((String?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/exchange_sonos"

        let (response, httpStatus) = postToServer(url: url, token: token, data: .init())

        guard httpStatus == ServerConstants.HttpConstants.ok, let response else {
            completion?(nil)
            return
        }

        let decoder = JSONDecoder()
        let data = try? decoder.decode(ExchangeResponse.self, from: response)

        completion?(data?.accessToken)
    }
}

private struct ExchangeResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
}
