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

            VStack(alignment: .leading) {
                Text(viewModel.title ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.primaryText01)
                Text(viewModel.author ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryText02)
            }

            Spacer()

            //TODO: Change source to Similar Shows
            SubscribeButtonView(podcastUuid: viewModel.uuid, source: .podcastScreen)
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
