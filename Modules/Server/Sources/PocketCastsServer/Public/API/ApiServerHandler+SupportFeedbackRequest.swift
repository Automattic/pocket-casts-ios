import Foundation

public extension ApiServerHandler {
    func sendFeedback(message: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let operation = SupportFeedbackTask(message: message)
            operation.completion = { success in
                continuation.resume(returning: success)
            }
            apiQueue.addOperation(operation)
        }
    }
}
