import Combine
import PocketCastsServer
import SwiftUI

@MainActor
class StoriesModel: ObservableObject {
    private(set) var progress: Double = 0 {
        didSet {
            progressModel.progress = progress
        }
    }

    @Published var currentStoryIndex: Int = 0

    @Published var isReady: Bool = false

    @Published var failed: Bool = false

    private var screenshotTaken: Bool = false {
        didSet {
            guard screenshotTaken else {
                if shareAlertState.isPresented {
                    setShareAlertPresented(false)
                }
                return
            }

            // Present share alert if the story is shareable
            guard dataSource.shareableStory(for: currentStoryIndex) != nil else {
                screenshotTaken = false
                return
            }

            setShareAlertPresented(true)
        }
    }

    let shareAlertState: StoriesShareAlertState

    let activeTier: () -> SubscriptionTier

    private let dataSource: StoriesDataSource
    private let publisher: Timer.TimerPublisher
    let configuration: StoriesConfiguration
    private let progressModel: StoriesProgressModel

    private var cancellables = Set<AnyCancellable>()

    private var cancellable: Cancellable?
    private var interval: TimeInterval {
        currentStory?.duration ?? 0
    }

    private var loadingCancellable: Cancellable?

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

    var indicatorHeight: CGFloat {
        configuration.indicatorHeight
    }

    var indicatorSpacing: CGFloat {
        configuration.indicatorSpacing
    }

    var progressPublisher: StoriesProgressModel {
        progressModel
    }

    init(
        dataSource: StoriesDataSource,
        configuration: StoriesConfiguration,
        progressModel: StoriesProgressModel = .shared,
        activeTier: @autoclosure @escaping () -> SubscriptionTier = SubscriptionHelper.activeTier
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.progressModel = progressModel
        self.publisher = Timer.publish(every: 0.01, on: .main, in: .default)
        self.activeTier = activeTier
        self.shareAlertState = StoriesShareAlertState()
        self.progressModel.progress = progress

        self.shareAlertState.onVisibilityChanged = { [weak self] isPresented in
            self?.shareAlertVisibilityChanged(isPresented)
        }

        refresh()

        subscribeToNotifications()
    }

    func refresh() {
        isReady = false

        Task.init {
            if self.configuration.loadingIsTheFirstStory {
                loadingStart()
            }
            let isReady = await dataSource.refresh()
            if configuration.loadingIsTheFirstStory, progress >= 1 {
                currentStoryIndex = 1
                Analytics.track(.endOfYearStoryShown, story: "cover")
            }
            self.isReady = isReady
            failed = !isReady
        }
    }

    func loadingStart() {
        loadingCancellable = publisher.autoconnect().sink(receiveValue: { _ in
            let newProgress = self.progress + (0.01 / EndOfYear.defaultDuration)
            if newProgress < 1 {
                self.progress = newProgress
            } else {
                self.progress = 1
            }
        })
    }

    func loadingEnded() {
        loadingCancellable = nil
        self.progress = 1.01
    }

    func start() {
        cancellable = publisher.autoconnect().sink(receiveValue: { _ in
            guard self.currentStory != nil, self.numberOfStories > 0 else {
                return
            }

            var newProgress = self.progress + (0.01 / self.interval)

            let currentStory = Int(newProgress)

            if currentStory >= self.numberOfStories || newProgress < 0 {
                if self.configuration.startOverFromBeginningAfterFinished {
                    newProgress = 0
                    self.currentStoryIndex = 0
                }
                else if self.configuration.closeAndDismissAfterFinished {
                    Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "auto_progress"])
                    self.stopAndDismiss()
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
        })

        currentStory?.onResume()
    }

    func story(index: Int) -> AnyView {
        let story = dataSource.story(for: index)

        // Only trigger onAppear if the story is not plus or user is paid
        // Otherwise, the paywall appears in front of the story
        if currentStory?.identifier != story.identifier, !story.plusOnly || isPaidUser() {
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
        let nextNonPlus: Int
        if EndOfYear.Year.y2025 == EndOfYear.currentYear {
            nextNonPlus = Int(progress.rounded(.down)) + numberOfPlusStoriesAfterTheCurrentOne() + 1
        } else {
            nextNonPlus = currentStoryIsPlus ? Int(progress.rounded(.down)) + numberOfPlusStoriesAfterTheCurrentOne() + 1: 0
        }

        manuallyChanged = true

        progress = min(Double(numberOfStories), Double(max(nextNonPlus, Int(progress) + 1)))
    }

    func previous() {
        guard isReady, numberOfStories > 0 else {
            return
        }

        let previousNonPlus: Int
        if EndOfYear.Year.y2025 == EndOfYear.currentYear {
            previousNonPlus = currentStoryIndex - numberOfPlusStoriesBeforeTheCurrentOne() - 1
        } else {
            previousNonPlus = currentStoryIndex - numberOfPlusStoriesBeforeTheCurrentOne()
        }

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
        EndOfYear.share(assets: assets, model: self, storyIdentifier: currentStoryIdentifier, onDismiss: { [weak self] in
            self?.start()
        })
    }

    func stopAndDismiss() {
        pause()
        NavigationManager.sharedManager.dismissPresentedViewController()
    }

    func shouldShowUpsell() -> Bool {
        if case EndOfYear.Year.y2025 = EndOfYear.currentYear {
            return false
        }
        return currentStoryIsPlus && activeTier() == .none
    }

    func paywallView() -> some View {
        dataSource.paywallView()
    }

    func overlaidShareView() -> AnyView? {
        dataSource.overlaidShareView()
    }

    func footerShareView() -> AnyView? {
        dataSource.footerShareView()
    }

    func indicatorColor(for storyIndex: Int) -> Color {
        dataSource.indicatorColor(for: storyIndex)
    }

    func indicatorStyle(for storyIndex: Int) -> StoryIndicatorStyle {
        dataSource.indicatorStyle(for: storyIndex)
    }

    var primaryBackgroundColor: Color {
        dataSource.primaryBackgroundColor
    }

    func sharingSnapshotModifier(_ view: AnyView) -> AnyView {
        dataSource.sharingSnapshotModifier(view)
    }

    func shouldShowDismissButton() -> Bool {
        configuration.shouldShowDismissButton
    }

    func recordPlaybackShare(properties: [String: String]) {
        Analytics.track(.playbackShared, properties: properties)
    }
}

private extension StoriesModel {
    func setShareAlertPresented(_ presented: Bool) {
        guard shareAlertState.isPresented != presented else { return }
        shareAlertState.isPresented = presented
    }

    func shareAlertVisibilityChanged(_ isPresented: Bool) {
        if !isPresented && screenshotTaken {
            screenshotTaken = false
        }
    }

    func subscribeToNotifications() {
        StoriesController.Notifications.allCases.forEach { [weak self] controller in
            switch controller {
            case .replay:
                NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: controller.rawValue), object: nil, queue: .main) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.replay()
                    }
                }
            case .share:
                NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: controller.rawValue), object: nil, queue: .main) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.share()
                    }
                }
            }
        }

        UIApplication.userDidTakeScreenshotNotification.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                pause()
                screenshotTaken = true

                if dataSource.shareableStory(for: currentStoryIndex) != nil {
                    let year = EndOfYear.currentYear.literalValue
                    let story = currentStoryIdentifier
                    let properties = ["story": story, "year": year, "from": "screenshot"]
                    Analytics.track(.endOfYearStoryShared, properties: properties)
                }
            }
            .store(in: &cancellables)

        if EndOfYear.currentYear != .y2025 {
            ServerNotifications.iapPurchaseCompleted.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
        }
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

final class StoriesShareAlertState: ObservableObject {
    @Published var isPresented: Bool = false {
        didSet {
            guard isPresented != oldValue else { return }
            onVisibilityChanged?(isPresented)
        }
    }

    var onVisibilityChanged: ((Bool) -> Void)?
}
