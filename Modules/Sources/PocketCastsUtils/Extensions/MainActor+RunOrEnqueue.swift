import Foundation

public extension MainActor {
    /// Runs `body` synchronously when called on the main thread, otherwise enqueues it on the main queue.
    static func runOrEnqueue(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.async {
                body()
            }
        }
    }
}
