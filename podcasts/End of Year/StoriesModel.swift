import Combine
import PocketCastsServer
import SwiftUI

@MainActor
class StoriesModel: ObservableObject {
    var progress: Double

    @Published var currentStoryIndex: Int = 0

    @Published var isReady: Bool = false

    @Published var failed: Bool = false

    @Published var screenshotTaken: Bool = false

    let activeTier: () -> SubscriptionTier

    private let dataSource: StoriesDataSource
    private let publisher: Timer.TimerPublisher
    private let configuration: StoriesConfiguration

    private var cancellables = Set<AnyCancellable>()

    private var cancellable: Cancellable?
    private var interval: TimeInterval {
        currentStory?.duration ?? 0
    }

    private var currentStoryIdentifier: String = ""

    private var currentStoryIsPlus = false

    private var manuallyChanged = false

    private var currentStory: Story?

    var numberOfStories: Int {
        dataSource.numberOfStories
    }

    var numberOfStoriesToPreload: Int {
        configuration.storiesToPreload
    }

    init(dataSource: StoriesDataSource, configuration: StoriesConfiguration, activeTier: @autoclosure @escaping () -> SubscriptionTier = SubscriptionHelper.activeTier) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.progress = 0
        self.publisher = Timer.publish(every: 0.01, on: .main, in: .default)
        self.activeTier = activeTier

        Task.init {
            await isReady = dataSource.isReady()
            failed = !isReady
        }

        subscribeToNotifications()
    }

    func refresh() {
        isReady = false

        Task.init {
            await isReady = dataSource.refresh()
            failed = !isReady
        }
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
                    self.currentStoryIndex = 0
                }
                else {
                    self.pause()
                }
            } else if currentStory != self.currentStoryIndex {
                if self.shouldSkipPlusStories() {
                    newProgress = Double(currentStory + self.numberOfPlusStoriesAfterTheCurrentOne())
                    self.currentStoryIndex = currentStory + self.numberOfPlusStoriesAfterTheCurrentOne()
                } else {
                    self.currentStoryIndex = currentStory
                }
                self.manuallyChanged = false
            }

            self.progress = newProgress
            StoriesProgressModel.shared.progress = newProgress
        })

        currentStory?.onResume()
    }

    func story(index: Int) -> AnyView {
        let story = dataSource.story(for: index)

        // Only trigger onAppear if the story is not plus or user is paid
        // Otherwise, the paywall appears in front of the story
        if !story.plusOnly || isPaidUser() {
            story.onAppear()
        }

        currentStory = story

        currentStoryIdentifier = story.identifier
        currentStoryIsPlus = story.plusOnly
        return AnyView(story)
    }

    func showShareButton(index: Int) -> Bool {
        dataSource.shareableStory(for: index)?.hideShareButton() == false
    }

    func preload(index: Int) -> AnyView {
        if index < numberOfStories {
            return AnyView(dataSource.story(for: index))
        }

        return AnyView(EmptyView())
    }

    func sharingAssets() -> [Any]? {
        guard let story = currentStory as? (any ShareableStory) else {
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
        guard isReady, numberOfStories > 0 else {
            return
        }

        let nextNonPlus = currentStoryIsPlus ? Int(progress.rounded(.down)) + numberOfPlusStoriesAfterTheCurrentOne() + 1 : 0

        manuallyChanged = true

        progress = min(Double(numberOfStories), Double(max(nextNonPlus, Int(progress) + 1)))
    }

    func previous() {
        guard isReady, numberOfStories > 0 else {
            return
        }

        let previousNonPlus = currentStoryIndex - numberOfPlusStoriesBeforeTheCurrentOne()

        manuallyChanged = true

        progress = max(0, Double(min(previousNonPlus, Int(progress) - 1)))
    }

    func numberOfPlusStoriesBeforeTheCurrentOne() -> Int {
        guard !isPaidUser() else {
            return 0
        }

        var currentStory = currentStoryIndex
        var numberOfStoriesToSkip = 0
        while currentStory > 0 && dataSource.story(for: currentStory - 1).plusOnly {
            numberOfStoriesToSkip += 1
            currentStory -= 1
        }

        return numberOfStoriesToSkip
    }

    func numberOfPlusStoriesAfterTheCurrentOne() -> Int {
        guard !isPaidUser() else {
            return 0
        }

        var currentStory = currentStoryIndex
        var numberOfStoriesToSkip = 0
        while currentStory + 1 < numberOfStories && dataSource.story(for: currentStory + 1).plusOnly {
            numberOfStoriesToSkip += 1
            currentStory += 1
        }

        return numberOfStoriesToSkip
    }

    func pause() {
        cancellable?.cancel()
        currentStory?.onPause()
    }

    func replay() {
        progress = 0
        currentStoryIndex = 0
        pause()
        start()
    }

    func share() {
        guard let assets = sharingAssets() else { return }

        pause()
        EndOfYear.share(assets: assets, storyIdentifier: currentStoryIdentifier, onDismiss: { [weak self] in
            self?.start()
        })
    }

    func stopAndDismiss() {
        pause()
        NavigationManager.sharedManager.dismissPresentedViewController()
    }

    func shouldShowUpsell() -> Bool {
        currentStoryIsPlus && activeTier() == .none
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

        UIApplication.userDidTakeScreenshotNotification.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pause()
                self?.screenshotTaken = true
            }
            .store(in: &cancellables)

        ServerNotifications.iapPurchaseCompleted.publisher()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.refresh()
        }
        .store(in: &cancellables)
    }

    func isPaidUser() -> Bool {
        activeTier() != .none
    }

    func nextStoryIsPlus() -> Bool {
        if currentStoryIndex + 1 < numberOfStories {
            return dataSource.story(for: currentStoryIndex + 1).plusOnly
        }

        return false
    }

    /// Whether some Plus stories should be skipped or not
    func shouldSkipPlusStories() -> Bool {
        !isPaidUser() && !manuallyChanged && currentStoryIsPlus && nextStoryIsPlus()
    }
}
