import Foundation

public struct AuthenticationResponse: Codable {
    public let token: String?
    public let uuid: String?
    public let email: String?

    internal init(from apiResponse: Api_UserLoginResponse) {
        token = apiResponse.token.isEmpty ? nil : apiResponse.token
        uuid = apiResponse.uuid.isEmpty ? nil : apiResponse.uuid
        email = apiResponse.email.isEmpty ? nil : apiResponse.email
    }
}
