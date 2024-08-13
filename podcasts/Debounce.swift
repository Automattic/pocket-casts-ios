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
}

class Throttle {
    private let frequency: Double
    private weak var timer: Timer?

    init(frequency: TimeInterval) {
        self.frequency = frequency
    }

    func call(_ callback: @escaping (() -> Void)) {
        if timer?.isValid == true {
            return
        }
        callback()
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: false) { obj in
            obj.invalidate()
        }
    }
}
