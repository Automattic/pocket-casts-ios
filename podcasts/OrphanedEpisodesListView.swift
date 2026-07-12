import SwiftUI
import PocketCastsDataModel

struct OrphanedEpisodesListView: View {
    @EnvironmentObject var theme: Theme

    let episodes: [Episode]

    @State private var expandedGroupIDs: Set<String>

    init(episodes: [Episode]) {
        self.episodes = episodes
        // Expanded by default: these lists are short, and the point is to surface the diagnostic
        // info immediately rather than hide it behind a tap.
        _expandedGroupIDs = State(initialValue: Set(episodes.map(\.podcastUuid)))
    }

    private struct PodcastGroup: Identifiable {
        let id: String
        let title: String
        let episodes: [Episode]
    }

    private var groups: [PodcastGroup] {
        Dictionary(grouping: episodes, by: \.podcastUuid)
            .map { podcastUuid, episodes in
                let title = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)?.title ?? podcastUuid
                let sortedEpisodes = episodes.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
                return PodcastGroup(id: podcastUuid, title: title, episodes: sortedEpisodes)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(groups) { group in
                DisclosureGroup(isExpanded: isExpanded(group.id)) {
                    ForEach(group.episodes, id: \.id) { episode in
                        episodeRow(episode)
                    }
                } label: {
                    groupLabel(group)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(L10n.troubleshootingViewOrphanedEpisodes)
        .applyDefaultThemeOptions()
    }

    private func groupLabel(_ group: PodcastGroup) -> some View {
        HStack(alignment: .center, spacing: 10) {
            PodcastImage(uuid: group.id, size: .list)
                .frame(width: 32, height: 32)
                .cornerRadius(6)

            Text(group.title)
                .font(.headline)
                .foregroundColor(theme.primaryText01)
                .lineLimit(1)

            Spacer()

            Text("\(group.episodes.count)")
                .foregroundColor(theme.primaryText02)
        }
        .padding(.vertical, 4)
    }

    private func episodeRow(_ episode: Episode) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(episode.title ?? episode.uuid)
                .font(.subheadline)
                .foregroundColor(theme.primaryText01)

            if let date = episode.publishedDate ?? episode.addedDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundColor(theme.primaryText02)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 38, bottom: 8, trailing: 16))
    }

    private func isExpanded(_ id: String) -> Binding<Bool> {
        Binding(
            get: { expandedGroupIDs.contains(id) },
            set: { expanded in
                if expanded {
                    expandedGroupIDs.insert(id)
                } else {
                    expandedGroupIDs.remove(id)
                }
            }
        )
    }
}

struct OrphanedEpisodesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OrphanedEpisodesListView(episodes: [])
        }
        .setupDefaultEnvironment()
    }
}
