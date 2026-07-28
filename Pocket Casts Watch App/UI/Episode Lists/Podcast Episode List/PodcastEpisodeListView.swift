import Kingfisher
import PocketCastsDataModel
import SwiftUI

struct PodcastEpisodeListView: View {
    let headerImageSize: CGFloat = 65

    @StateObject var viewModel: PodcastEpisodeListViewModel

    var body: some View {
        List {
            Section {
                EpisodeListView(title: L10n.podcastsPlural.prefixSourceUnicode, showArtwork: false, episodes: $viewModel.episodes, playlist: .podcast(uuid: viewModel.podcast.uuid))
            } header: {
                podcastInfo.textCase(.none)
            }
        }
        .navigationTitle(L10n.podcastsPlural.prefixSourceUnicode)
        .withOrderPickerToolbar(selectedOption: viewModel.sortOption, title: L10n.sortEpisodes, hasHorizontalPadding: true) { option in
            viewModel.didChangeSortOrder(option: option)
        }
    }

    var podcastInfo: some View {
        VStack(alignment: .center) {
            CachedImage(url: viewModel.podcast.artworkURL)
                .frame(width: headerImageSize, height: headerImageSize, alignment: .center)
            Text(viewModel.podcast.title ?? "")
                .font(.dynamic(size: 16))
                .foregroundColor(.white)
            Text(viewModel.podcast.author ?? "")
                .font(.dynamic(size: 12))
                .foregroundColor(.subheadlineText)
                .padding(.bottom, 3)
            if viewModel.episodes.isEmpty {
                Text(L10n.watchNoEpisodes)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
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
