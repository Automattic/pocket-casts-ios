import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SmartPlaylistRulesView: View {
    @State var isExpanded: Bool = false
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: PlaylistPreviewViewModel

    var body: some View {
        List {
            switch viewModel.playlistMode {
            case .creation:
                if viewModel.isInPreview {
                    SmartPlaylistRulesInPreviewSection(
                        enabledRules: viewModel.enabledRules,
                        availableRules: viewModel.availableRules,
                        viewModel: viewModel
                    )

                    SmartPlaylistRulesEpisodesSection(
                        episodes: viewModel.episodes,
                        playlistName: viewModel.newPlaylist.playlistName
                    )
                } else {
                    SmartPlaylistRulesDefaultSection(
                        title: viewModel.newPlaylist.playlistName,
                        description: L10n.playlistSmartPreviewDescription,
                        availableRules: viewModel.availableRules,
                        viewModel: viewModel
                    )
                }
            case .edit:
                SmartPlaylistRulesDefaultSection(
                    title: L10n.playlistSmartRulesTitle,
                    description: nil,
                    availableRules: viewModel.availableRules,
                    viewModel: viewModel
                )

                if viewModel.newPlaylistHasChanged {
                    SmartPlaylistRulesEpisodesSection(
                        episodes: viewModel.episodes,
                        playlistName: viewModel.newPlaylist.playlistName
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
    }
}

fileprivate struct SmartPlaylistRulesDefaultSection: View {
    @EnvironmentObject var theme: Theme

    let title: String
    let description: String?
    let availableRules: [SmartPlaylistRuleInfo]
    let viewModel: PlaylistPreviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(size: 22.0, style: .title2, weight: .bold)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(theme.primaryText01)
            if let description {
                Text(description)
                    .font(size: 14.0, style: .body, weight: .regular)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .listRowClearStyle()

        SmartPlaylistRulesSectionView(
            rules: availableRules,
            viewModel: viewModel,
            action: viewModel.action
        )
    }
}

fileprivate struct SmartPlaylistRulesInPreviewSection: View {
    @State var isExpanded: Bool = false
    @EnvironmentObject var theme: Theme

    let enabledRules: [SmartPlaylistRuleInfo]
    let availableRules: [SmartPlaylistRuleInfo]
    let viewModel: PlaylistPreviewViewModel

    var body: some View {
        if !enabledRules.isEmpty {
            SmartPlaylistRulesSectionView(
                rules: enabledRules,
                viewModel: viewModel,
                action: viewModel.action
            )
        }
        if !availableRules.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                SmartPlaylistRulesSectionView(
                    rules: availableRules,
                    viewModel: viewModel,
                    action: viewModel.action
                )
            } label: {
                Text(L10n.playlistSmartPreviewMoreRules)
                    .font(size: 22.0, style: .title2, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
            }
            .accentColor(theme.primaryIcon01)
            .animation(.default, value: isExpanded)
        }
    }
}

struct SmartPlaylistRulesEpisodesSection: View {
    @EnvironmentObject var theme: Theme

    let episodes: [ListEpisode]
    let playlistName: String

    var body: some View {
        Group {
            Text(L10n.playlistPreviewTitle(playlistName))
                .font(size: 22.0, style: .title2, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 32.0)
                .padding(.bottom, 16.0)
                .padding(.horizontal, 16.0)
                .listRowClearStyle()

            if episodes.isEmpty {
                EmptyStateView(
                    title: FeatureFlag.playlistsRebranding.enabled ? L10n.filterCreateNoEpisodes.sentenceCased : L10n.filterCreateNoEpisodes,
                    message: L10n.playlistCreateNoEpisodesDescription,
                    icon: {
                        Image("empty-playlist-info")
                    },
                    actions: [],
                    style: .defaultStyle
                )
                .listRowClearStyle()
                .padding(.horizontal, 16.0)
            } else {
                ForEach(episodes, id: \.id) { episode in
                    PlaylistEpisodePreviewRowView(
                        episode: episode.episode
                    )
                        .frame(minHeight: 80)
                        .listRowClearStyle()
                }
                .padding(.leading, 16.0)
            }
        }
    }
}

fileprivate extension View {
    func listRowClearStyle() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(EmptyView())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @EnvironmentObject var theme: Theme

        var body: some View {
            VStack {
                SmartPlaylistRulesView(
                    viewModel: viewModel
                )
                Spacer()
            }
        }

        private var viewModel: PlaylistPreviewViewModel {
            let viewModel = PlaylistPreviewViewModel(
                newPlaylist: model(),
                playlistMode: .creation) { _ in }
            return viewModel
        }

        private func model() -> EpisodeFilter {
            let filter = EpisodeFilter()
            filter.playlistName = "New Releases"
            filter.podcastSmartRuleApplied = true
            return filter
        }
    }

    return PreviewWrapper()
        .environmentObject(Theme.sharedTheme)
}
