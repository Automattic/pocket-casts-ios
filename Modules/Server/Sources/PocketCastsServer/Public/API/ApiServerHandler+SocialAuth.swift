import Foundation
import PocketCastsDataModel
import PocketCastsUtils

public extension ApiServerHandler {
    func validateLogin(identityToken: Data?, completion: @escaping (Result<AuthenticationResponse, APIError>) -> Void) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login_apple")
        guard var request = ServerHelper.createEmptyProtoRequest(url: url),
              let identityToken = identityToken,
              let token = String(data: identityToken, encoding: .utf8)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token")
            completion(.failure(.UNKNOWN))
            return
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        obtainToken(request: request, completion: completion)
    }
}
