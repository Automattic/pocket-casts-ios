import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct PodcastTableCellView: View {

    enum Style {
        case regular
        case large

        var size: CGFloat {
            switch self {
                case .regular:
                    return 48
                case .large:
                    return 56
            }
        }
    }

    @EnvironmentObject var theme: Theme

    let viewModel: PodcastCellViewModel
    let style: Style
    let onSubscribe: ((PodcastCellViewModel) -> Void)?

    init(viewModel: PodcastCellViewModel, style: Style = .regular, onSubscribe: ((PodcastCellViewModel) -> Void)? = nil) {
        self.viewModel = viewModel
        self.style = style
        self.onSubscribe = onSubscribe
    }

    var body: some View {
        HStack(spacing: 8) {
            PodcastImage(uuid: viewModel.uuid)
                .frame(width: style.size, height: style.size)
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

            SubscribeButtonView(podcastUuid: viewModel.uuid, source: .podcastScreenYouMightLike, onSubscribe: {
                viewModel.onSubscribe?(viewModel)
            })
        }
    }
}

struct PodcastCellViewModel {
    let uuid: String
    let datetime: String?
    let title: String?
    let author: String?
    let onSubscribe: ((Self) -> Void)?

    init(podcast: Podcast, datetime: String?) {
        self.uuid = podcast.uuid
        self.title = podcast.title
        self.author = podcast.author
        self.datetime = datetime
        self.onSubscribe = nil
    }

    init(discoverPodcast: DiscoverPodcast, datetime: String?, onSubscribe: ((Self) -> Void)?) {
        self.uuid = discoverPodcast.uuid ?? ""
        self.title = discoverPodcast.title
        self.author = discoverPodcast.author
        self.datetime = datetime
        self.onSubscribe = onSubscribe
    }

    init(podcastSearchResult: PodcastFolderSearchResult, onSubscribe: ((Self) -> Void)? = nil) {
        self.uuid = podcastSearchResult.uuid
        self.datetime = nil
        self.author = podcastSearchResult.author
        self.title = podcastSearchResult.title
        self.onSubscribe = onSubscribe
    }
}
