import Foundation
import PocketCastsDataModel
import PocketCastsUtils

// MARK: - Device Code Authentication
public struct DeviceAuthorizationResponse {
    public let deviceCode: String
    public let userCode: String
    public let verificationURI: String
    public let verificationURIComplete: String
}

public extension ApiServerHandler {

    func deviceAuthorizeRequest(scope: String) async throws -> DeviceAuthorizationResponse {
        try await withCheckedThrowingContinuation { continuation in
            deviceAuthorizeRequest(scope: scope) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let result):
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func deviceAuthorizeRequest(scope: String, completion: @escaping (Result<DeviceAuthorizationResponse, APIError>) -> Void) {
        var request = Api_DeviceAuthorizeRequest()
        request.scope = scope

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "device/authorize")

        do {
            let data = try request.serializedData()
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                FileLog.shared.addMessage("Unable to create protobuffer request to device authorize code")
                completion(.failure(APIError.UNKNOWN))
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let responseData = data, error == nil, (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok else {
                    let errorResponse = ApiServerHandler.extractErrorResponse(data: data, response: response)
                    completion(.failure(errorResponse ?? APIError.UNKNOWN))
                    return
                }

                do {
                    let response = try Api_DeviceAuthorizeResponse(jsonUTF8Data: responseData)
                    let externalResponse = DeviceAuthorizationResponse(deviceCode: response.deviceCode, userCode: response.userCode, verificationURI: response.verificationUri, verificationURIComplete: response.verificationUriComplete)
                    completion(.success(externalResponse))
                } catch {
                    completion(.failure(APIError.UNKNOWN))
                }
            }.resume()
        } catch {
            FileLog.shared.addMessage("Device Authorization Request failed \(error.localizedDescription)")
            completion(.failure(APIError.UNKNOWN))
        }
    }

    func deviceGetToken(deviceCode: String, scope: AuthenticationScope = .tv) async throws -> AuthenticationResponse {
        guard let request = deviceTokenRequest(deviceCode: deviceCode, scope: scope)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token via Apple SSO")
            throw APIError.UNKNOWN
        }

        return try await obtainToken(request: request, usingRefreshToken: true)
    }

    private func deviceTokenRequest(deviceCode: String,
                                    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                    timeoutInterval: TimeInterval = 15.seconds, scope:
                                    AuthenticationScope = .tv) -> URLRequest? {
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/token")

        var data = Api_UserTokenRequest()
        data.grantType = "urn:ietf:params:oauth:grant-type:device_code"
        data.scope = scope.rawValue
        data.deviceCode = deviceCode

        return ServerHelper.createProtoRequest(url: url, data: try! data.serializedData())
    }
}
