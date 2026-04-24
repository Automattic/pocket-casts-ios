import Foundation

/// Coalesces and debounces reload requests from notification bursts, with a
/// pause hook so callers can briefly defer flushes while UI animations run.
/// When the pause ends, any requests that arrived in the meantime are flushed
/// as a single call with the union of the requested scopes.
@MainActor
public final class ReloadDebouncer<Scope: OptionSet> {
    private let debounce: Duration
    private let onReload: (Scope) -> Void
    private var pending: Scope?
    private var flushTask: Task<Void, Never>?
    private var resumeTask: Task<Void, Never>?
    private var isPaused = false

    public init(debounce: Duration = .milliseconds(100), onReload: @escaping (Scope) -> Void) {
        self.debounce = debounce
        self.onReload = onReload
    }

    /// Flushed with the union of requested scopes after the debounce window.
    public func request(_ scope: Scope) {
        if pending == nil {
            pending = scope
        } else {
            pending?.formUnion(scope)
        }
        scheduleFlush()
    }

    /// Schedules a flush with no additional scope flags. Useful when the caller
    /// only wants to trigger the debounced reload without narrowing scope.
    public func request() {
        request(Scope())
    }

    /// Suspends flushes.
    public func pause(for duration: Duration? = nil) {
        isPaused = true
        flushTask?.cancel()
        flushTask = nil
    }

    /// Resumes flushing; any request queued while paused is flushed next.
    public func resume() {
        isPaused = false
        resumeTask?.cancel()
        resumeTask = nil
        if pending != nil {
            scheduleFlush()
        }
    }

    // Suspends flushes for the given duration, then auto-resumes.
    public func pause(for duration: Duration) {
        pause()
        resume(after: duration)
    }

    public func resume(after duration: Duration) {
        guard isPaused else { return }
        resumeTask?.cancel()
        resumeTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.resume()
        }
    }

    private func scheduleFlush() {
        guard !isPaused else { return }
        flushTask?.cancel()
        flushTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    private func flush() {
        flushTask = nil
        guard !isPaused, let scope = pending else { return }
        pending = nil
        onReload(scope)
    }


    /// Awaits any scheduled flush or auto-resume work. For tests.
    func waitForIdle() async {
        while true {
            if let resumeTask {
                await resumeTask.value
                continue
            }
            if let flushTask {
                await flushTask.value
                continue
            }
            return
        }
    }
}
