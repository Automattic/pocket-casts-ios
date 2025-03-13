import Combine
import Foundation

import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastHeaderViewModel: ObservableObject {

    @Published var podcast: Podcast

    private(set) weak var delegate: PodcastActionsDelegate?

    init(podcast: Podcast, delegate: PodcastActionsDelegate? = nil) {
        self.podcast = podcast
        self.delegate = delegate
        addObservers()
    }

    @Published var isExpanded: Bool = true

    private var cancellables = Set<AnyCancellable>()
    private func addObservers() {
        NotificationCenter.default.publisher(for: Constants.Notifications.podcastUpdated)
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            guard let podcastUuid = notification.object as? String,
                  podcastUuid == podcast.uuid,
                  let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
            else {
                return
            }

            self.podcast = podcast
        }
        .store(in: &cancellables)
    }

    lazy var podcastRatingViewModel: PodcastRatingViewModel = {
        let podcastRatingViewModel = PodcastRatingViewModel()
        podcastRatingViewModel.update(podcast: podcast)
        return podcastRatingViewModel
    }()

    var folderImage: String {
        let folderImage = SubscriptionHelper.hasActiveSubscription() ? (podcast.folderUuid?.isEmpty ?? true) ? "folder-empty" : "folder-check" : "folder-create"
        return folderImage
    }

    var displayCategory: String {
        var result = podcast.podcastCategory?.localized(seperatingWith: \.isNewline) ?? ""
        if let author = podcast.author {
            result += " · \(author)"
        }
        return result
    }

    var displayAuthor: String? {
        guard let podcastAuthor = podcast.author else {
            return nil
        }
        return podcastAuthor
    }

    var displayWebsite: String? {
        guard let websiteUrl = podcast.podcastUrl, let host = URL(string: websiteUrl)?.host else {
            return nil
        }
        if host.startsWith(string: "www.") {
            let wwwIndex = host.index(host.startIndex, offsetBy: 4)
            return String(host[wwwIndex...])
        } else {
            return host
        }
    }

    var displayFrequency: String? {
        guard let frequency = podcast.displayableFrequency() else {
            return nil
        }
        return L10n.paidPodcastReleaseFrequencyFormat(frequency)
    }

    var displayNextEpisodeDate: String? {
        guard let estimatedDate = podcast.displayableNextEpisodeDate() else {
            return nil
        }
        return L10n.paidPodcastNextEpisodeFormat(estimatedDate)
    }

    var isPodcastSubscribed: Bool {
        return podcast.isSubscribed()
    }

    func subscribeButtonTapped() {
        guard let delegate = delegate else { return }

        if podcast.isSubscribed() {
            delegate.unsubscribe()
        } else {
            delegate.subscribe()
            isExpanded = false
        }
    }
}
