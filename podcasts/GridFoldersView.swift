import SwiftUI

struct SuggestedFolder: Identifiable {
    var id: String {
        return name
    }

    let name: String
    let color: Int32
    let topPodcastUuids: [String]
}

struct GridFoldersView: View {

    var folders: [SuggestedFolder]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 160))], alignment: .center, spacing: 6) {
                ForEach(folders) { folder in
                    NavigationLink(destination: SuggestedFolderPodcastView(folder: folder)) {
                        SuggestedFolderPreviewWrapper(folder: folder)
                            .cornerRadius(4)
                            .frame(minWidth: 110, maxWidth: 160)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}
