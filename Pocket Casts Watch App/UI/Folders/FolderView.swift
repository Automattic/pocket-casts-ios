import SwiftUI

struct FolderView: View {
    @StateObject var viewModel: FolderViewModel

    var body: some View {
        ItemListContainer(isEmpty: viewModel.podcasts.isEmpty, noItemsTitle: L10n.watchNoPodcasts) {
            List {
                ForEach(viewModel.podcasts) { podcast in
                    NavigationLink(destination: PodcastEpisodeListView(viewModel: PodcastEpisodeListViewModel(podcast: podcast))) {
                        HStack {
                            CachedImage(url: podcast.smallArtworkURL, cornerRadius: 0)
                                .frame(width: WatchConstants.Interface.podcastIconSize, height: WatchConstants.Interface.podcastIconSize)

                            Text(podcast.title ?? "")
                                .font(.dynamic(size: 16))
                        }
                        .padding(.leading, -3)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(viewModel.folder.name.prefixSourceUnicode)
    }
}
