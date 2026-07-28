import Combine
import Foundation

public final class ContextUpdateDebouncer {
    private let subject = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable?

    public init(interval: TimeInterval, scheduler: DispatchQueue = .main, handler: @escaping () -> Void) {
        let debounceInterval = DispatchQueue.SchedulerTimeType.Stride.milliseconds(Int(interval * 1000))
        cancellable = subject
            .debounce(for: debounceInterval, scheduler: scheduler)
            .sink { handler() }
    }

    public func call() {
        subject.send(())
    }
}
