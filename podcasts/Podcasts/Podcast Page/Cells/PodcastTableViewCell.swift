import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

final class PodcastTableViewCell: ThemeableCell {
    static var reuseIdentifier: String = "PodcastTableViewCell"
    private var viewModel: PodcastCellViewModel?

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        viewModel = nil
    }

    func configure(with viewModel: PodcastCellViewModel) {
        self.selectedStyle = .primaryUi02Active

        self.viewModel = viewModel

        self.contentConfiguration = UIHostingConfiguration {
            PodcastTableCellView(viewModel: viewModel)
                .environmentObject(Theme.sharedTheme)
        }
        .margins(.horizontal, 16)
        .margins(.vertical, 8)
    }

    func configure(with discoverPodcast: DiscoverPodcast, datetime: String?, onSubscribe: ((PodcastCellViewModel) -> Void)?) {
        configure(with: PodcastCellViewModel(discoverPodcast: discoverPodcast, datetime: datetime, onSubscribe: onSubscribe))
    }

    private enum ClientError: Swift.Error {
        case noPodcastUuid
        case podcastNotFound
        case episodeNotFound
    }

    func load(podcast: String) async throws -> Podcast {
        if let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcast, includeUnsubscribed: true) {
            return existingPodcast
        }

        return try await withCheckedThrowingContinuation { continuation in
            ServerPodcastManager.shared.addFromUuid(podcastUuid: podcast, subscribe: false) { added in
                if added, let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcast, includeUnsubscribed: true) {
                    continuation.resume(returning: existingPodcast)
                } else {
                    continuation.resume(throwing: ClientError.podcastNotFound)
                }
            }
        }
    }
}
