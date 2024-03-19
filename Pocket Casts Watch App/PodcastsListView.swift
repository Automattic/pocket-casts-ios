import PocketCastsDataModel
import SwiftUI

struct PodcastsListView: View {
    @StateObject var viewModel = PodcastsListViewModel()

    var body: some View {
        ItemListContainer(isEmpty: viewModel.gridItems.isEmpty, noItemsTitle: L10n.watchNoPodcasts) {
            List {
                ForEach(viewModel.gridItems) { gridItem in
                    if let podcast = gridItem.podcast {
                        PodcastItemView(podcast: podcast)
                    } else if let folder = gridItem.folder {
                        FolderItemView(folder: folder, podcastCount: viewModel.countOfPodcastsInFolder(folder))
                    }
                }
                .withOrderPickerToolbar(selectedOption: viewModel.sortOrder, title: L10n.podcastsSort) { option in
                    viewModel.sortOrder = option
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(L10n.podcastsPlural.prefixSourceUnicode)
    }
}

struct PodcastItemView: View {
    @State var podcast: Podcast

    var body: some View {
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

struct FolderItemView: View {
    @State var folder: Folder
    let podcastCount: Int

    var body: some View {
        NavigationLink(destination: FolderView(viewModel: FolderViewModel(folder: folder))) {
            HStack {
                Image("folder")
                    .resizable()
                    .frame(width: WatchConstants.Interface.podcastIconSize, height: WatchConstants.Interface.podcastIconSize)
                VStack(alignment: .leading) {
                    Text(folder.name)
                        .font(.dynamic(size: 16))
                    Text(L10n.podcastCount(podcastCount))
                        .font(.dynamic(size: 16))
                        .foregroundColor(.subheadlineText)
                }
            }
            .padding(.leading, -3)
        }
    }
}

struct PodcastsListView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            PodcastsListView()
                .previewDevice($0)
        }
    }
}
