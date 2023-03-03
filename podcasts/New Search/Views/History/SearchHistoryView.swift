import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

    private var episode: Episode {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        return episode
    }

    init() {
        UITableViewHeaderFooterView.appearance().backgroundView = UIView()
    }

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            List {
                ThemeableListHeader(title: L10n.searchRecent, actionTitle: L10n.historyClearAll)

                Section {
                    SearchHistoryCell(podcast: Podcast.previewPodcast())
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchHistoryCell(searchTerm: "Search term")
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchHistoryCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }
            }
        }
        .background(AppTheme.color(for: .primaryUi04, theme: theme))
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
            .previewWithAllThemes()
    }
}
