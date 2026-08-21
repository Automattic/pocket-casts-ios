import Foundation

extension OperationQueue {
    /// Suspends until all the operations currently in the queue have finished, without blocking a
    /// thread the way `waitUntilAllOperationsAreFinished()` does.
    func allOperationsFinished() async {
        await withCheckedContinuation { continuation in
            addBarrierBlock {
                continuation.resume()
            }
        }
    }
}

extension DispatchGroup {
    /// Suspends until the group is empty, without blocking a thread the way `wait()` does.
    func finished() async {
        await withCheckedContinuation { continuation in
            notify(queue: .global()) {
                continuation.resume()
            }
        }
    }
}
