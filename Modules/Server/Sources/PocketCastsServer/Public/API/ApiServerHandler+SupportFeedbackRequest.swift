import Foundation

public extension ApiServerHandler {
    func sendFeedback(message: String) async {
        await sendFeedback(message: message, feedbackType: .authenticated)
    }

    func sendAnonymousFeedback(message: String) async {
        await sendFeedback(message: message, feedbackType: .anonymous)
    }

    private func sendFeedback(message: String, feedbackType: SupportFeedbackTask.FeedbackType) async {
        await withCheckedContinuation { continuation in
            let operation = SupportFeedbackTask(message: message, feedbackType: feedbackType)
            operation.completion = { _ in
                continuation.resume()
            }
            apiQueue.addOperation(operation)
        }
    }
}
