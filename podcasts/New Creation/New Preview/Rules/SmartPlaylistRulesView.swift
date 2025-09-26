import SwiftUI
import PocketCastsDataModel

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
                        action: viewModel.action
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
                        action: viewModel.action
                    )
                }
            case .edit:
                SmartPlaylistRulesDefaultSection(
                    title: L10n.playlistSmartRulesTitle,
                    description: nil,
                    availableRules: viewModel.availableRules,
                    action: viewModel.action
                )
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
    let action: (SmartPlaylistRule) -> Void

    var body: some View {
        Group {
            Text(title)
                .font(size: 22.0, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .listRowClearStyle()
            if let description {
                Text(description)
                    .font(size: 14.0, style: .body, weight: .regular)
                    .lineLimit(2)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4.0)
                    .padding(.trailing, 8.0)
                    .listRowClearStyle()
            }
            SmartPlaylistRulesContainerView(
                rules: availableRules,
                action: action
            )
            .padding(.top, 24.0)
            .listRowClearStyle()
        }
        .padding(.horizontal, 16.0)
    }
}

fileprivate struct SmartPlaylistRulesInPreviewSection: View {
    @State var isExpanded: Bool = false
    @EnvironmentObject var theme: Theme

    let enabledRules: [SmartPlaylistRuleInfo]
    let availableRules: [SmartPlaylistRuleInfo]
    let action: (SmartPlaylistRule) -> Void

    var body: some View {
        Group {
            if !enabledRules.isEmpty {
                Text(L10n.playlistSmartPreviewEnabledRules)
                    .font(size: 22.0, style: .body, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .listRowClearStyle()
                SmartPlaylistRulesContainerView(
                    rules: enabledRules,
                    action: action
                )
                .padding(.vertical, 16.0)
                .listRowClearStyle()
            }

            if !availableRules.isEmpty {
                DisclosureGroup(isExpanded: $isExpanded) {
                    SmartPlaylistRulesContainerView(
                        rules: availableRules,
                        action: action
                    )
                    .listRowClearStyle()
                    .padding(.vertical, 16.0)
                    .padding(.leading, -18.0)
                } label: {
                    Text(L10n.playlistSmartPreviewOtherRules)
                        .font(size: 22.0, style: .body, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                        .listRowClearStyle()
                }
                .accentColor(theme.primaryIcon01)
                .animation(.default, value: isExpanded)
                .listRowClearStyle()
            }
        }
        .padding(.horizontal, 16.0)
    }
}

struct SmartPlaylistRulesEpisodesSection: View {
    @EnvironmentObject var theme: Theme

    let episodes: [ListEpisode]
    let playlistName: String

    var body: some View {
        Group {
            Text(L10n.playlistPreviewTitle(playlistName))
                .font(size: 22.0, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .padding(.top, 16.0)
                .padding(.bottom, 16.0)
                .padding(.horizontal, 16.0)
                .listRowClearStyle()

            if episodes.isEmpty {
                EmptyStateView(
                    title: L10n.filterCreateNoEpisodes,
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
