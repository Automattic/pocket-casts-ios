import Kingfisher
import PocketCastsDataModel
import SwiftUI

struct PodcastEpisodeListView: View {
    let headerImageSize: CGFloat = 65

    @StateObject var viewModel: PodcastEpisodeListViewModel

    var body: some View {
        ScrollView {
            LazyVStack {
                podcastInfo
                EpisodeListView(title: L10n.podcastsPlural.prefixSourceUnicode, showArtwork: false, episodes: $viewModel.episodes)
            }
        }
        .navigationTitle(L10n.podcastsPlural.prefixSourceUnicode)
        .withOrderPickerToolbar(selectedOption: viewModel.sortOption, title: L10n.sortEpisodes, hasHorizontalPadding: true) { option in
            viewModel.didChangeSortOrder(option: option)
        }
    }

    var podcastInfo: some View {
        Group {
            CachedImage(url: viewModel.podcast.artworkURL)
                .frame(width: headerImageSize, height: headerImageSize, alignment: .center)
            Text(viewModel.podcast.title ?? "")
            Text(viewModel.podcast.author ?? "")
                .font(.dynamic(size: 12))
                .foregroundColor(.subheadlineText)
                .padding(.bottom, 3)
            if viewModel.episodes.isEmpty {
                Text(L10n.watchNoEpisodes)
                    .font(.subheadline)
            }
        }
        .multilineTextAlignment(.center)
    }
}

struct PodcastEpisodeListView_Previews: PreviewProvider {
    static let testViewModel = PodcastEpisodeListViewModel(podcast: Podcast())

    static var previews: some View {
        ForEach(PreviewDevice.previewDevices, id: \.rawValue) { device in
            PodcastEpisodeListView(viewModel: testViewModel)
                .previewDevice(device)
        }
    }
}
