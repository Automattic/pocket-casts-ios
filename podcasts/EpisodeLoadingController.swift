import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

// MARK: - Async Episode Loader

class EpisodeLoadingModel: ObservableObject {
    @Published var error = false
}

struct EpisodeLoadingView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var episodeLoadingModel: EpisodeLoadingModel

    var body: some View {
        ZStack(alignment: .center) {
            if !episodeLoadingModel.error {
                ProgressView()
                    .tint(AppTheme.loadingActivityColor().color)
                    .scaleEffect(x: 2, y: 2, anchor: .center)
            } else {
                Text(L10n.discoverEpisodeFailToLoad)
                    .font(size: 14, style: .subheadline, weight: .medium)
                    .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                    .padding(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyDefaultThemeOptions()
    }
}

class EpisodeLoadingController: UIHostingController<AnyView> {
    private let episodeUuid: String
    private let podcastUuid: String
    private let timestamp: TimeInterval?

    private let episodeLoadingModel = EpisodeLoadingModel()

    init(episodeUuid: String, podcastUuid: String, timestamp: TimeInterval? = nil) {
        self.episodeUuid = episodeUuid
        self.podcastUuid = podcastUuid
        self.timestamp = timestamp

        super.init(rootView: AnyView(EpisodeLoadingView(episodeLoadingModel: episodeLoadingModel).setupDefaultEnvironment()))
    }

    // Do a quick check to see if we need to load this episode or not
    static func needsLoading(uuid: String) -> Bool {
        DataManager.sharedManager.findEpisode(uuid: uuid) == nil
    }

    // Helpers to get the episode/podcast for checks
    private var episode: Episode? {
        DataManager.sharedManager.findEpisode(uuid: episodeUuid)
    }

    private var podcast: Podcast? {
        DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start the loading and print an error if it fails
        Task {
            guard await loadEpisode() == true else {
                episodeLoadingModel.error = true
                return
            }

            doneLoading()
        }
    }

    func loadEpisode() async -> Bool {
        await withCheckedContinuation { continuation in
            // If we're missing the podcast, then load that and the episode
            if self.podcast == nil {
                ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)
            }
            // If we're missing just the episode then get that
            else {
                _ = ServerPodcastManager.shared.addMissingEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)
            }

            // Verify they were added
            let success = podcast != nil && episode != nil
            continuation.resume(with: .success(success))
        }
    }

    @MainActor func doneLoading() {
        // Push to the controller and fade into it
        let controller = EpisodeDetailViewController(episodeUuid: episodeUuid, source: .homeScreenWidget, timestamp: timestamp)

        navigationController?.delegate = self
        navigationController?.setViewControllers([controller], animated: true)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// This is a bit of a hack to make it appear like the loading view is an overlay of the episode controller,
/// but in reality it's in a navigation controller and we're pushing to it
extension EpisodeLoadingController: UIViewControllerAnimatedTransitioning, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)

        guard let fromView, let toView else {
            return
        }

        // Add the episode controller below the loading view so we can fade into it
        transitionContext.containerView.insertSubview(toView.view, belowSubview: fromView.view)

        let duration = transitionDuration(using: transitionContext)

        // We delay the alpha transition here because the episode controller has a weird animation effect when it first loads
        UIView.animate(withDuration: duration, delay: 0.3) {
            fromView.view.alpha = 0
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}
