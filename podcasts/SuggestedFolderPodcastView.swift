import SwiftUI

struct SuggestedFolderPodcastView: View {
    @EnvironmentObject var theme: Theme

    let folder: SuggestedFolder

    let source: AnalyticsSource

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 160))], alignment: .center, spacing: 6) {
                ForEach(folder.podcastUuids, id: \.self) { uuid in
                    PodcastImageViewWrapper(podcastUUID: uuid, size: .grid)
                        .frame(minWidth: 110, maxWidth: 160)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .navigationTitle(folder.name)
        }
        // hack to allow the scroll indicator to be visible without overlapping the content
        .customHorizontalMargin(margin: SuggestedFoldersView.Constants.margin)
        .applyDefaultThemeOptions()
        .onAppear {
            Analytics.track(.suggestedFoldersPreviewFolderTapped, properties: ["source": source.rawValue, "folder_name": folder.name, "podcasts_count": folder.podcastUuids.count])
        }
    }
}
