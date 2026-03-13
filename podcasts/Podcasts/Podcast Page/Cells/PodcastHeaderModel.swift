import Combine
import Foundation

import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastHeaderViewModel: NSObject, ObservableObject {

    @Published var podcast: Podcast

    private(set) weak var delegate: PodcastActionsDelegate?

    init(podcast: Podcast, delegate: PodcastActionsDelegate? = nil) {
        self.podcast = podcast
        self.delegate = delegate
        self.isSubscribed = podcast.isSubscribed()
        _isExpanded =  Published(initialValue: delegate?.isSummaryExpanded() ?? false)
        super.init()
        addObservers()
    }

    @Published var isExpanded: Bool = true

    @Published var isSubscribed: Bool = false

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
            self.isSubscribed = podcast.isSubscribed()
        }
        .store(in: &cancellables)
    }

    lazy var podcastRatingViewModel: PodcastRatingViewModel = {
        let podcastRatingViewModel = PodcastRatingViewModel()
        podcastRatingViewModel.update(podcast: podcast)
        podcastRatingViewModel.presentLogin = { [weak self] _ in
            self?.delegate?.showLogin(message: L10n.ratingLoginRequired)
        }
        return podcastRatingViewModel
    }()

    var folderImage: String {
        let isSubscriptionAvailable = SubscriptionHelper.hasActiveSubscription() && SyncManager.isUserLoggedIn()
        let folderImage = isSubscriptionAvailable ? (podcast.folderUuid?.isEmpty ?? true) ? "folder-empty" : "folder-check" : "folder-create"
        return folderImage
    }

    var firstCategory: String {
        guard let category = podcast.podcastCategory,
              let substring = category.split(whereSeparator: \.isNewline).first
        else {
            return ""
        }
        return String(substring).lowercased()
    }

    var displayCategoryAndAuthor: AttributedString {
        let category = podcast.podcastCategory?.localized(seperatingWith: \.isNewline) ?? ""
        var markdown = "[\(category)](http://pocketcasts.com)"
        if let author = podcast.author {
            markdown += " · \(author)"
        }
        return (try? AttributedString(markdown: markdown)) ?? AttributedString("")
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

        if podcast.isSubscribed() || isSubscribed {
            delegate.unsubscribe()
            // do not switch variable here because there is still a confimation screen
        } else {
            delegate.subscribe()
            // switching state immediately so animation is triggered at press
            isSubscribed = true
        }
    }

    func websiteLinkTapped() {
        guard let website = podcast.podcastUrl, let url = URL(string: website) else { return }
        Analytics.track(.podcastScreenPodcastDetailsLinkTapped, properties: ["podcast_uuid": podcast.uuid])
        delegate?.open(url: url)
    }

    func toggleExpanded() {
        let willBeExpanded = !isExpanded
        delegate?.setSummaryExpanded(expanded: willBeExpanded)
        Analytics.track(.podcastScreenToggleSummary, properties: ["is_expanded": willBeExpanded])
        isExpanded.toggle()
    }

    var htmlDescription: String {
        return podcast.podcastHTMLDescription ?? podcast.podcastDescription ?? ""
    }

    func categoryTapped() {
        delegate?.categoryTapped(firstCategory)
    }

    func podcastArtworkTapped() {
        delegate?.refreshArtwork()
    }
}

extension PodcastHeaderViewModel: ExpandableLabelDelegate {
    // MARK: - ExpandableLabelDelegate

    func willExpandLabel(_ label: UIView) {
        Analytics.track(.podcastScreenPodcastDescriptionTapped)
        delegate?.tableView().beginUpdates()
    }

    func didExpandLabel(_ label: UIView) {
        delegate?.tableView().endUpdates()
        delegate?.setDescriptionExpanded(expanded: true)
    }

    func willCollapseLabel(_ label: UIView) {
        Analytics.track(.podcastScreenPodcastDescriptionTapped)
        delegate?.tableView().beginUpdates()
    }

    func didCollapseLabel(_ label: UIView) {
        delegate?.tableView().endUpdates()
        delegate?.setDescriptionExpanded(expanded: false)
    }

    func linkTapped(url: URL) {
        if let uuid = delegate?.displayedPodcast()?.uuid {
            Analytics.track(.podcastScreenPodcastDescriptionLinkTapped, properties: ["podcast_uuid": uuid])
        }
        delegate?.open(url: url)
    }
}
