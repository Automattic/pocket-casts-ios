import Combine
import PocketCastsServer
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

    private var currentStoryIdentifier: String = ""

    private var currentStoryIsPlus = false

    private var manuallyChanged = false

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
            guard self.numberOfStories > 0 else {
                return
            }

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
                self.currentStory = self.nextAvailableStory(currentStory)
                newProgress = Double(self.currentStory)
            }

            self.progress = newProgress
            StoriesProgressModel.shared.progress = newProgress
        })
    }

    func story(index: Int) -> AnyView {
        let story = dataSource.story(for: index)
        story.onAppear()
        currentStoryIdentifier = story.identifier
        return AnyView(story)
    }

    func storyIsShareable(index: Int) -> Bool {
        dataSource.shareableStory(for: index) != nil ? true : false
    }

    func preload(index: Int) -> AnyView {
        if index < numberOfStories {
            return AnyView(dataSource.story(for: index))
        }

        return AnyView(EmptyView())
    }

    func sharingAssets() -> [Any]? {
        guard let story = dataSource.shareableStory(for: currentStory) else {
            return nil
        }

        story.willShare()

        // If any of the assets have additional handlers then make sure we add them to the array
        return story.sharingAssets().flatMap {
            if let item = $0 as? ShareableMetadataDataSource {
                return [$0, item.shareableMetadataProvider]
            }

            return [$0]
        }
    }

    func isInteractiveView(index: Int) -> Bool {
        dataSource.isInteractiveView(for: index)
    }

    func next() {
        guard numberOfStories > 0 else {
            return
        }

        progress = Double(nextAvailableStory(min(numberOfStories, Int(progress) + 1)))
    }

    func previous() {
        guard numberOfStories > 0 else {
            return
        }

        progress = Double(previousAvailableStory(max(0, Int(progress) - 1)))
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

    func share() {
        guard let assets = sharingAssets() else { return }

        pause()
        EndOfYear().share(assets: assets, storyIdentifier: currentStoryIdentifier, onDismiss: { [weak self] in
            self?.start()
        })
    }

    func stopAndDismiss() {
        pause()
        NavigationManager.sharedManager.dismissPresentedViewController()
    }

    /// Calculates the next story index to jump to
    func nextAvailableStory(_ next: Int) -> Int {
        let story = dataSource.story(for: currentStory)
        var nextAvailable = next

        if !story.feature.isUnlocked {
            while !dataSource.story(for: nextAvailable).feature.isUnlocked {
                nextAvailable += 1
            }
        }

        return nextAvailable
    }
    
    /// Calculates the previous story index to jump to
    func previousAvailableStory(_ previous: Int) -> Int {
        let previousStory = dataSource.story(for: previous)
        var prevAvailable = previous

        // If the next story is locked, then find the first unlocked story
        if !previousStory.feature.isUnlocked {
            while !dataSource.story(for: prevAvailable).feature.isUnlocked {
                prevAvailable -= 1
            }

            // Jump forward to show the first locked story
            prevAvailable += 1
        }

        return prevAvailable
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
