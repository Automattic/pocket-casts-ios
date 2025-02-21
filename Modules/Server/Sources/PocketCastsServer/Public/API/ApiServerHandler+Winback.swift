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
}
