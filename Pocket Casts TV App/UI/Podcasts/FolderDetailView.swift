import SwiftUI
import PocketCastsDataModel

struct FolderDetailView: View {

    @State var model: FolderDetailViewModel

    init(folder: Folder) {
        self.model = FolderDetailViewModel(folder: folder)
    }

    enum Layout {
        static var gridSize = CGFloat(250)
    }
    private static let gridColumns: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    @Namespace private var podcastGridNamespace

    var body: some View {
        let firstID = model.podcasts.first?.id
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(model.folder.name)
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
                LazyVGrid(columns: Self.gridColumns, spacing: 48) {
                    ForEach(model.podcasts) { podcast in
                        NavigationLink(value: podcast) {
                            PodcastImage(uuid: podcast.uuid, size: .page)
                                .frame(width: Layout.gridSize, height: Layout.gridSize)
                        }
                        .buttonStyle(.card)
                        .prefersDefaultFocus(podcast.id == firstID, in: podcastGridNamespace)
                    }
                }
                .focusScope(podcastGridNamespace)
            }
        }
        .navigationDestination(for: Podcast.self) { podcast in
            PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
        }
        .task {
            model.load()
        }
    }
}

#Preview {
    NavigationStack {
        FolderDetailView(folder: MockData.makeStubFolders().first!)
    }
}
