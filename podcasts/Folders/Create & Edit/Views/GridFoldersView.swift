import SwiftUI

struct GridFoldersView: View {

    var folders: [SuggestedFolder]
    var source: AnalyticsSource

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 160))], alignment: .center, spacing: 6) {
                ForEach(folders) { folder in
                    NavigationLink(destination: SuggestedFolderPodcastView(folder: folder, source: source)) {
                        SuggestedFolderPreviewWrapper(folder: folder)
                            .cornerRadius(4)
                            .frame(minWidth: 90, maxWidth: 160)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}
