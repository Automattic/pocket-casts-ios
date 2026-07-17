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
        _ = try? await ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)

        return podcast != nil && episode != nil
    }

    @MainActor func doneLoading() {
        transitionToEpisodeControllerFadingIntoIt()
    }

    private func transitionToEpisodeControllerFadingIntoIt() {
        let controller = EpisodeDetailViewController(episodeUuid: episodeUuid, source: .homeScreenWidget, timestamp: timestamp)

        view.addSubview(controller.view)
        controller.view.alpha = 0
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.anchorToAllSidesOf(view: view)
        addChild(controller)
        controller.didMove(toParent: self)

        UIView.animate(withDuration: 0.2) {
            controller.view.alpha = 1
        }
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
