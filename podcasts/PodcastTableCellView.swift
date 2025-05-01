import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct PodcastTableCellView: View {
    @EnvironmentObject var theme: Theme
    let viewModel: PodcastCellViewModel

    var body: some View {
        HStack(spacing: 8) {
            PodcastImage(uuid: viewModel.uuid)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.title ?? "")
                    .lineLimit(1)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.primaryText01)
                Text(viewModel.author ?? "")
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(theme.primaryText02)
            }

            Spacer()

            SubscribeButtonView(podcastUuid: viewModel.uuid, source: .podcastScreenSimilarShows)
        }
    }
}

struct PodcastCellViewModel {
    let uuid: String
    let title: String?
    let author: String?

    init(podcast: Podcast) {
        self.uuid = podcast.uuid
        self.title = podcast.title
        self.author = podcast.author
    }

    init(discoverPodcast: DiscoverPodcast) {
        self.uuid = discoverPodcast.uuid ?? ""
        self.title = discoverPodcast.title
        self.author = discoverPodcast.author
    }
}
