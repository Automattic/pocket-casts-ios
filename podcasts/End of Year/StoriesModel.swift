import Combine

class StoriesModel: ObservableObject {
    @Published var progress: Double

    private var items: Int
    private let publisher: Timer.TimerPublisher
    private var cancellable: Cancellable?
    private var interval: TimeInterval = 5.seconds

    init(items: Int) {
        self.items = items
        self.progress = 0
        self.publisher = Timer.publish(every: 0.01, on: .main, in: .default)
    }

    func start() {
        cancellable = publisher.autoconnect().sink(receiveValue: {  _ in
            var newProgress = self.progress + (0.01 / self.interval)
            if Int(newProgress) >= self.items { newProgress = 0 }
            self.progress = newProgress
        })
    }
}
