import Foundation

public extension ApiServerHandler {
    /// Sends a request to the server that checks the users receipt to see if they are eligible for a free trial
    func checkTrialEligibility(_ base64EncodedReceipt: String, completion: @escaping (_ isEligible: Bool?) -> Void) {
        let request = makeEligibilityRequest(receipt: base64EncodedReceipt)
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "subscription/check_eligibility")

        guard
            let requestData = try? request.serializedData(),
            let request = ServerHelper.createProtoRequest(url: url, data: requestData)
        else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            guard let data = data, error == nil, urlResponse?.extractStatusCode() == ServerConstants.HttpConstants.ok else {
                completion(nil)
                return
            }

            let eligible = (try? Api_CheckEligibleResponse(serializedData: data))?.eligible

            completion(eligible)
        }.resume()
    }
}

private extension ApiServerHandler {
    private func makeEligibilityRequest(receipt: String) -> Api_CheckEligibleRequest {
        var appleRequest = Api_SubscriptionsPurchaseAppleRequest()
        appleRequest.receipt = receipt

        var request = Api_CheckEligibleRequest()
        request.storeReceipt = .apple(appleRequest)

        return request
    }
}
