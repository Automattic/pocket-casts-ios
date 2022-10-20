import Combine
import SwiftUI

@MainActor
class StoriesModel: ObservableObject {
    @Published var progress: Double

    @Published var currentStory: Int = 0

    @Published var isReady: Bool = false

    private let dataSource: StoriesDataSource
    private let publisher: Timer.TimerPublisher
    private let configuration: StoriesConfiguration

    private var cancellable: Cancellable?
    private var interval: TimeInterval {
        dataSource.story(for: currentStory).duration
    }

    var numberOfStories: Int {
        dataSource.numberOfStories
    }

    init(dataSource: StoriesDataSource, configuration: StoriesConfiguration) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.progress = 0
        self.publisher = Timer.publish(every: 0.01, on: .main, in: .default)
        Task.init {
            await isReady = dataSource.isReady()
        }
    }

    func start() {
        cancellable = publisher.autoconnect().sink(receiveValue: { _ in
            var newProgress = self.progress + (0.01 / self.interval)

            let currentStory = Int(newProgress)

            if currentStory >= self.numberOfStories || newProgress < 0 {
                if self.configuration.startOverFromBeginningAfterFinished {
                    newProgress = 0
                    self.currentStory = 0
                }
                else {
                    self.pause()
                }
            } else if currentStory != self.currentStory {
                self.currentStory = currentStory
            }

            self.progress = newProgress
        })
    }

    func story(index: Int) -> AnyView {
        dataSource.storyView(for: index)
    }

    func interactive(index: Int) -> AnyView {
        dataSource.interactiveView(for: index)
    }

    func shareableAsset(index: Int) -> Any {
        dataSource.shareableAsset(for: index)
    }

    func next() {
        progress = Double(Int(progress) + 1)
    }

    func previous() {
        progress = Double(Int(progress) - 1)
    }

    func pause() {
        cancellable?.cancel()
    }
}
