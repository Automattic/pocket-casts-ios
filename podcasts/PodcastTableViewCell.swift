final class PodcastTableViewCell: UITableViewCell {
    static var reuseIdentifier: String = "PodcastTableViewCell"
    private var viewModel: PodcastCellViewModel?

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        viewModel = nil
    }

    func configure(with viewModel: PodcastCellViewModel) {
        self.viewModel = viewModel

        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration {
                PodcastTableCellView(viewModel: viewModel)
                    .environmentObject(Theme.sharedTheme)
            }
        } else {
            let view = PodcastTableCellView(viewModel: viewModel)
            let uiView = view.environmentObject(Theme.sharedTheme).uiView
            contentView.addSubview(uiView)
        }
    }

    func configure(with discoverPodcast: DiscoverPodcast) {
        configure(with: PodcastCellViewModel(discoverPodcast: discoverPodcast))
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
