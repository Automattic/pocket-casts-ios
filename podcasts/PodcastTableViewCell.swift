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
        if #available(iOS 16.0, *) {
        } else {
            contentView.subviews.forEach { $0.removeFromSuperview() }
        }
    }

    func configure(with viewModel: PodcastCellViewModel) {
        self.selectedStyle = .primaryUi02Active

        self.viewModel = viewModel

        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration {
                PodcastTableCellView(viewModel: viewModel)
                    .environmentObject(Theme.sharedTheme)
            }
            .margins(.horizontal, 16)
            .margins(.vertical, 8)
        } else {
            let view = PodcastTableCellView(viewModel: viewModel)
            let uiView = view.environmentObject(Theme.sharedTheme).uiView
            uiView.translatesAutoresizingMaskIntoConstraints = false
            uiView.backgroundColor = .clear
            contentView.addSubview(uiView)
            NSLayoutConstraint.activate([
                contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
                contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
                contentView.topAnchor.constraint(equalTo: uiView.topAnchor)
            ])
        }
    }

    func configure(with discoverPodcast: DiscoverPodcast, datetime: String?) {
        configure(with: PodcastCellViewModel(discoverPodcast: discoverPodcast, datetime: datetime))
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
