import Foundation

extension ApiServerHandler {
    public func loadWinbackOffer() async -> WinbackOfferInfo? {
        return await withCheckedContinuation { continuation in
            let operation = WinbackOfferTask()
            operation.completion = { offerInfo in
                continuation.resume(returning: offerInfo)
            }
            apiQueue.addOperation(operation)
        }
    }

    public func submitSurveyResult(reason: String, other: String?) async -> Bool {
        return await withCheckedContinuation { continuation in
            let operation = CancelSubscriptionSurveyTask(reason: reason, other: other)
            operation.completion = { success in
                continuation.resume(returning: success)
            }
            apiQueue.addOperation(operation)
        }
    }
}
