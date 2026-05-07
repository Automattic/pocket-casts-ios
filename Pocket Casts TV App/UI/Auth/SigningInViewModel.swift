import SwiftUI
import Combine

@Observable
class SigningInViewModel {
    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case waiting
        case finished
    }
    var state: State = .waiting

    var podcasts: [MockPodcast] = MockData.makePodcasts()

    func sync() {
        cancellable = Timer.publish(every: 5.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self else { return }
                        state = .finished
                    }
    }
}
