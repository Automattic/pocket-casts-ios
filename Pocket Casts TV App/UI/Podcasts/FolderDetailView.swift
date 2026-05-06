import SwiftUI

struct FolderDetailView: View {
    let folder: MockFolder

    private let gridColumns: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(PodcastsView.Layout.gridSize), spacing: 48)
    }

    @Namespace private var podcastGridNamespace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(folder.name)
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
                LazyVGrid(columns: gridColumns, spacing: 48) {
                    ForEach(folder.podcasts) { podcast in
                        NavigationLink(value: podcast) {
                            Image(podcast.image)
                                .resizable()
                                .frame(width: PodcastsView.Layout.gridSize, height: PodcastsView.Layout.gridSize)
                        }
                        .buttonStyle(.card)
                        .prefersDefaultFocus(folder.podcasts.first?.id == podcast.id, in: podcastGridNamespace)
                    }
                }
                .focusScope(podcastGridNamespace)
            }
        }
        .navigationDestination(for: MockPodcast.self) { podcast in
            PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
        }
    }
}

#Preview {
    NavigationStack {
        FolderDetailView(folder: MockData.makeFolders().first!)
    }
}
