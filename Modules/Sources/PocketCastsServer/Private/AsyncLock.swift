import Foundation

/// A mutex that can be held across suspension points.
///
/// `objc_sync_enter` and `NSLock` tie ownership to a thread, so they can't guard work that awaits,
/// and an actor on its own isn't enough because actors are reentrant: another call can interleave
/// while the first one is suspended. Work between `lock()` and `unlock()` runs to completion before
/// the next caller gets the lock.
actor AsyncLock {
    private var isLocked = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func lock() async {
        guard isLocked else {
            isLocked = true

            return
        }

        await withCheckedContinuation { continuation in
            waiting.append(continuation)
        }
    }

    func unlock() {
        guard !waiting.isEmpty else {
            isLocked = false

            return
        }

        // hand the lock straight to the next caller in line
        waiting.removeFirst().resume()
    }
}
