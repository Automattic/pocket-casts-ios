import Foundation

public class TimedActionHelper {
    private var timer: Timer?

    private var action: (() -> Void)?

    public init() {}

    public func startTimer(for time: TimeInterval, action: @escaping () -> Void) {
        self.action = action
        performStartTimer(for: time)
    }

    public func cancelTimer() {
        performCancelTimer()
    }

    public func isTimerValid() -> Bool {
        guard let timer = timer else {
            return false
        }
        return timer.isValid
    }

    private func performStartTimer(for time: TimeInterval) {
        performCancelTimer()

        // Timers need to run on a thread that has a runloop, the easiest one being the main thread so we use that here
        if Thread.isMainThread {
            timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
        } else {
            DispatchQueue.main.sync { [weak self] in
                guard let self else { return }

                self.timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: false)
            }
        }
    }

    private func performCancelTimer() {
        // a Timer must always be invalidated from the thread it was created on, in our case being the main thread
        if Thread.isMainThread {
            timer?.invalidate()
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.timer?.invalidate()
            }
        }

        timer = nil
    }

    @objc private func timerFired() {
        action?()
        timer = nil
    }
}
