import Foundation

public class Debounce {
    private let delay: Double
    private weak var timer: Timer?

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    public func call(_ callback: @escaping (() -> Void)) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            callback()
        }
    }

    public func cancel() {
        timer?.invalidate()
    }
}
