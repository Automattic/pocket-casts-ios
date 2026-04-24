import Foundation

/// Coalesces reload requests from notification bursts. The first request in
/// a quiet period fires on the next run-loop turn; any further requests that
/// arrive within `debounce` of that flush are unioned and fire once at the
/// end of the window. A pause hook lets callers defer flushes while UI
/// animations run; pending requests are flushed on resume.
@MainActor
public final class ReloadScheduler<Scope: OptionSet> {
    private let interval: Duration
    private let onReload: (Scope) -> Void
    private var pending: Scope?
    private var flushTask: Task<Void, Never>?
    private var resumeTask: Task<Void, Never>?
    private var isPaused = false
    private var lastFlushAt: ContinuousClock.Instant?

    public init(interval: Duration = .milliseconds(100), onReload: @escaping (Scope) -> Void) {
        self.interval = interval
        self.onReload = onReload
    }

    /// Fires on the leading edge of a quiet window, then coalesces further
    /// requests into a single trailing flush at the end of the cooldown.
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
        guard !isPaused, flushTask == nil else { return }
        let delay: Duration = lastFlushAt.map {
            max(.zero, ContinuousClock.now.duration(to: $0.advanced(by: interval)))
        } ?? .zero
        flushTask = Task { [weak self, delay] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    private func flush() {
        flushTask = nil
        guard !isPaused, let scope = pending else { return }
        pending = nil
        lastFlushAt = ContinuousClock.now
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
