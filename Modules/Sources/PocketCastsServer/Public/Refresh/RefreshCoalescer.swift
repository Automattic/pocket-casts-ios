import Foundation
import PocketCastsUtils

/// Lets a refresh of all podcasts join one that's already running instead of starting another.
final class RefreshCoalescer: @unchecked Sendable {
    private let lock = NSLock()
    private let maximumDuration: TimeInterval
    private var running: (id: UUID, startDate: Date)?
    private var completions: [(RefreshFetchResult) -> Void] = []

    /// - Parameter maximumDuration: How long a refresh can run before new ones stop joining it.
    init(maximumDuration: TimeInterval = 10.minutes) {
        self.maximumDuration = maximumDuration
    }

    /// Starts a refresh, or joins the running one.
    ///
    /// - Returns: The ID to pass to `finish(id:result:)` when the caller should start a refresh, or `nil` when
    /// it joined the running one, which then calls `completion` when it finishes.
    func begin(completion: ((RefreshFetchResult) -> Void)?, now: Date = Date()) -> UUID? {
        lock.withLock {
            if let running, now.timeIntervalSince(running.startDate) < maximumDuration {
                if let completion { completions.append(completion) }
                return nil
            }

            let id = UUID()
            running = (id, now)
            completions = completion.map { [$0] } ?? []
            return id
        }
    }

    /// Ends the refresh with the given ID and calls everyone waiting for it.
    func finish(id: UUID, result: RefreshFetchResult) {
        let waiting: [(RefreshFetchResult) -> Void] = lock.withLock {
            guard running?.id == id else { return [] }

            defer {
                running = nil
                completions = []
            }
            return completions
        }
        waiting.forEach { $0(result) }
    }

    /// Ends the running refresh, if any, as failed.
    func cancel() {
        guard let id = lock.withLock({ running?.id }) else { return }

        finish(id: id, result: .failed)
    }
}
