import Foundation

public struct AuthenticationResponse: Codable {
    public let token: String?
    public let uuid: String?
    public let email: String?
    public let refreshToken: String?
    public let isNewAccount: Bool?

    internal init(from apiResponse: Api_UserLoginResponse) {
        token = apiResponse.token.isEmpty ? nil : apiResponse.token
        uuid = apiResponse.uuid.isEmpty ? nil : apiResponse.uuid
        email = apiResponse.email.isEmpty ? nil : apiResponse.email
        refreshToken = nil
        isNewAccount = false
    }

    internal init(from apiResponse: Api_TokenLoginResponse) {
        token = apiResponse.accessToken.isEmpty ? nil : apiResponse.accessToken
        uuid = apiResponse.uuid.isEmpty ? nil : apiResponse.uuid
        email = apiResponse.email.isEmpty ? nil : apiResponse.email
        refreshToken = apiResponse.refreshToken
        isNewAccount = apiResponse.isNew
    }
}
