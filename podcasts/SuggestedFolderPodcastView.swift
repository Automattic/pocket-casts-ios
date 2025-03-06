import SwiftUI

struct SuggestedFolderPodcastView: View {
    @EnvironmentObject var theme: Theme

    let folder: SuggestedFolder

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 160))], alignment: .center, spacing: 6) {
                ForEach(folder.topPodcastUuids, id: \.self) { uuid in
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
            Analytics.track(.suggestedFoldersDetailModalShown, properties: [:])
        }
    }
}
