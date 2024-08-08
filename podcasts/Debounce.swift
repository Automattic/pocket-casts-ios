import Foundation

class Debounce {
    private let delay: Double
    private weak var timer: Timer?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func call(_ callback: @escaping (() -> Void)) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            callback()
        }
    }

    func cancel() {
        timer?.invalidate()
    }
}
