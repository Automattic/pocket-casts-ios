import Combine
import SwiftUI

@MainActor
class StoriesModel: ObservableObject {
    var progress: Double

    @Published var currentStory: Int = 0

    @Published var isReady: Bool = false

    @Published var failed: Bool = false

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

    var numberOfStoriesToPreload: Int {
        configuration.storiesToPreload
    }

    init(dataSource: StoriesDataSource, configuration: StoriesConfiguration) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.progress = 0
        self.publisher = Timer.publish(every: 0.01, on: .main, in: .default)

        Task.init {
            await isReady = dataSource.isReady()
            failed = !isReady
        }

        subscribeToNotifications()
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
            StoriesProgressModel.shared.progress = newProgress
        })
    }

    func story(index: Int) -> AnyView {
        dataSource.storyView(for: index)
    }

    func preload(index: Int) -> AnyView {
        if index < numberOfStories {
            return AnyView(dataSource.story(for: index))
        }

        return AnyView(EmptyView())
    }

    func sharingAssets() -> [Any] {
        dataSource.story(for: currentStory).sharingAssets()
    }

    func interactive(index: Int) -> AnyView {
        dataSource.interactiveView(for: index)
    }

    func shareableAsset(index: Int) -> Any {
        dataSource.shareableAsset(for: index)
    }

    func next() {
        progress = min(Double(numberOfStories), Double(Int(progress) + 1))
    }

    func previous() {
        progress = max(0, Double(Int(progress) - 1))
    }

    func pause() {
        cancellable?.cancel()
    }

    func replay() {
        progress = 0
        currentStory = 0
        pause()
        start()
    }
}

private extension StoriesModel {
    func subscribeToNotifications() {
        StoriesController.Notifications.allCases.forEach { [weak self] controller in
            switch controller {
            case .replay:
                NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: controller.rawValue), object: nil, queue: .main) { [weak self] _ in
                    self?.replay()
                }
            }
        }
    }
}
