#if !os(watchOS)
    import CFNetwork
#endif
import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftyJSON

public extension ApiServerHandler {
    func validateLogin(username: String, password: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        obtainToken(username: username, password: password, scope: ServerConstants.Values.apiScope) { token, error in
            completion(token != nil, error)
        }
    }
    
    func forgotPassword(email: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        var request = Api_EmailRequest()
        request.email = email
        
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/forgot_password")
        do {
            let data = try request.serializedData()
            
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                completion(false, nil)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let responseData = data, error == nil, (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok else {
                    let errorResponse = ApiServerHandler.extractErrorResponse(data: data)
                    completion(false, errorResponse)
                    
                    return
                }
                
                do {
                    let response = try Api_UserChangeResponse(serializedData: responseData)
                    completion(response.success.value, nil)
                }
                catch {
                    completion(false, nil)
                }
            }.resume()
        }
        catch {
            FileLog.shared.addMessage("forgotPassword failed \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    func registerAccount(username: String, password: String, completion: @escaping (_ success: Bool, _ error: APIError?) -> Void) {
        var request = Api_RegisterRequest()
        request.email = username
        request.password = password
        request.scope = ServerConstants.Values.apiScope
        
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/register")
        do {
            let data = try request.serializedData()
            
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                completion(false, nil)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let responseData = data, error == nil, (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok else {
                    let errorResponse = ApiServerHandler.extractErrorResponse(data: data)
                    completion(false, errorResponse)
                    
                    return
                }
                
                do {
                    let response = try Api_RegisterResponse(serializedData: responseData)
                    completion(response.success.value, nil)
                }
                catch {
                    completion(false, nil)
                }
                
            }.resume()
        }
        catch {
            FileLog.shared.addMessage("registerAccount failed \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    func obtainToken(username: String, password: String, scope: String, completion: @escaping (_ token: String?, _ error: APIError?) -> Void) {
        var loginRequest = Api_UserLoginRequest()
        loginRequest.email = username
        loginRequest.password = password
        loginRequest.scope = scope
        
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login")
        do {
            let data = try loginRequest.serializedData()
            
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                FileLog.shared.addMessage("Unable to create protobuffer request to obtain token")
                completion(nil, nil)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let responseData = data, error == nil, response?.extractStatusCode() == ServerConstants.HttpConstants.ok else {
                    let errorResponse = ApiServerHandler.extractErrorResponse(data: data, error: error)
                    FileLog.shared.addMessage("Unable to obtain token, status code: \(response?.extractStatusCode() ?? -1), server error: \(errorResponse?.rawValue ?? "none")")
                    completion(nil, errorResponse)
                    
                    return
                }
                
                do {
                    let token = try Api_UserLoginResponse(serializedData: responseData).token
                    completion(token, nil)
                }
                catch {
                    FileLog.shared.addMessage("Error occurred while trying to unpack token request \(error.localizedDescription)")
                    completion(nil, nil)
                }
                
            }.resume()
        }
        catch {
            FileLog.shared.addMessage("obtainToken failed \(error.localizedDescription)")
            completion(nil, nil)
        }
    }
    
    private class func extractErrorResponse(data: Data?, error: Error? = nil) -> APIError? {
        if let data = data {
            do {
                let errorJson = try JSON(data: data)
                return APIError(rawValue: errorJson["errorMessageId"].stringValue) ?? APIError.UNKNOWN
            }
            catch {
                FileLog.shared.addMessage("Unable to decode error response \(error.localizedDescription)")
            }
        }

        #if !os(watchOS)
            if let err = error as NSError?, err.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue {
                return APIError.NO_CONNECTION
            }
        #endif
        
        return nil
    }
    
    // MARK: Change email and password
    
    func changeEmailRequest(newEmail: String, password: String, completion: @escaping (Bool) -> Void) {
        let operation = ChangeEmailTask(newEmail: newEmail, password: password)
        operation.completion = completion
        apiQueue.addOperation(operation)
    }
    
    func changePasswordRequest(currentPassword: String, newPassword: String, completion: @escaping (Bool) -> Void) {
        let operation = ChangePasswordTask(currentPassword: currentPassword, newPassword: newPassword)
        operation.completion = completion
        apiQueue.addOperation(operation)
    }
    
    // MARK: - Subscription Tasks
    
    func sendPurchaseReceipt(completion: @escaping (Bool) -> Void) {
        guard ServerSettings.syncingEmail() != nil else {
            FileLog.shared.addMessage("Purchase receipt not send as user has no sync email")
            completion(false)
            return
        }
        
        let operation = PurchaseReceiptTask()
        operation.completion = completion
        apiQueue.addOperation(operation)
    }
    
    func retrieveSubscriptionStatus() {
        let subscriptionStatusTask = SubscriptionStatusTask()
        apiQueue.addOperation(subscriptionStatusTask)
    }
    
    // MARK: - Subscription Promotion Codes
    
    func redeemPromoCode(promoCode: String, completion: @escaping (Int, String?, APIError?) -> Void) {
        let redeemOperation = RedeemPromoCodeTask(promoCode: promoCode)
        redeemOperation.completion = completion
        apiQueue.addOperation(redeemOperation)
    }
}
