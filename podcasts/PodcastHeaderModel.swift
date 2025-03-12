import Foundation

import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastHeaderViewModel: ObservableObject {
    let podcast: Podcast
    private(set) weak var delegate: PodcastActionsDelegate?

    init(podcast: Podcast, delegate: PodcastActionsDelegate? = nil) {
        self.podcast = podcast
        self.delegate = delegate
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

    var displayAuthor: String {
        guard let podcastAuthor = podcast.author else {
            return ""
        }
        return podcastAuthor
    }

    var displayWebsite: String {
        guard let websiteUrl = podcast.podcastUrl, let host = URL(string: websiteUrl)?.host else {
            return ""
        }
        if host.startsWith(string: "www.") {
            let wwwIndex = host.index(host.startIndex, offsetBy: 4)
            return String(host[wwwIndex...])
        } else {
            return host
        }
    }

    var displayFrequency: String {
        guard let frequency = podcast.displayableFrequency() else {
            return ""
        }
        return L10n.paidPodcastReleaseFrequencyFormat(frequency)
    }

    var displayNextEpisodeDate: String {
        guard let estimatedDate = podcast.displayableNextEpisodeDate() else {
            return ""
        }
        return L10n.paidPodcastNextEpisodeFormat(estimatedDate)
    }
}
