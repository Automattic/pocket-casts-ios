import Foundation

public extension ApiServerHandler {

    func getReferralCode() async -> ReferralCode? {
        return await withCheckedContinuation { continuation in
            let operation = ReferralGetCodeTask()
            operation.completion = { code in
                continuation.resume(returning: code)
            }
            apiQueue.addOperation(operation)
        }
    }

    func validateCode(_ code: String) async -> ReferralValidate? {
        return await withCheckedContinuation { continuation in
            let operation = ReferralValidateTask(code: code)
            operation.completion = { code in
                continuation.resume(returning: code)
            }
            apiQueue.addOperation(operation)
        }
    }

    func redeemCode(_ code: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let operation = ReferralRedeemTask(code: code)
            operation.completion = { result in
                continuation.resume(returning: result)
            }
            apiQueue.addOperation(operation)
        }
    }
}
