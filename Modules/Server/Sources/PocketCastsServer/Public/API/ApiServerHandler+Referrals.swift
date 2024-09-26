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
}
