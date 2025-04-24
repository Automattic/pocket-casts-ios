import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct PodcastTableCellView: View {
    @EnvironmentObject var theme: Theme

    let podcast: Podcast

    var body: some View {
        HStack(spacing: 8) {
            PodcastImage(uuid: podcast.uuid)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading) {
                Text(podcast.title ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.primaryText01)
                Text(podcast.author ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryText02)
            }

            Spacer()

            //TODO: Change source to Similar Shows
            SubscribeButtonView(podcastUuid: podcast.uuid, source: .podcastScreen)
        }
    }
}

final class PodcastTableViewCell: UITableViewCell {

    static var reuseIdentifier: String = "PodcastTableViewCell"

    override func prepareForReuse() {
        super.prepareForReuse()

        contentConfiguration = nil
    }

    func configure(with uuid: String) {
        //TODO: Add task to something
        Task {
            let podcast = try await load(podcast: uuid)

            if #available(iOS 16.0, *) {
                self.contentConfiguration = UIHostingConfiguration {
                    PodcastTableCellView(podcast: podcast)
                        .environmentObject(Theme.sharedTheme)
                }
            } else {
                let view = PodcastTableCellView(podcast: podcast)
                let uiView = view.environmentObject(Theme.sharedTheme).uiView
                contentView.addSubview(uiView)
            }
        }
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
