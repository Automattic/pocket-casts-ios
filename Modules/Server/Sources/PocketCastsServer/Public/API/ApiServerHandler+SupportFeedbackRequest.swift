import Foundation

public extension ApiServerHandler {
    func sendFeedback(message: String) {
        let operation = SupportFeedbackTask(message: message)
        apiQueue.addOperation(operation)
    }
}
