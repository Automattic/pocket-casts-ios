import Foundation

/// Runs the listening-history sync on a GCD queue, one at a time: a run asked for while one is
/// in progress waits for that one. The next run after it ends syncs again.
actor Playback2026HistorySync {
    private let sync: @Sendable () -> Void
    private var inFlight: Task<Void, Never>?

    init(sync: @escaping @Sendable () -> Void) {
        self.sync = sync
    }

    func run() async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task { [sync] in
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    sync()
                    continuation.resume()
                }
            }
            finish()
        }
        inFlight = task
        await task.value
    }

    private func finish() {
        inFlight = nil
    }
}
