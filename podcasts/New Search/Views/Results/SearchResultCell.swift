import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @StateObject var model: SearchResultCellModel

    let played: Bool
    let showDivider: Bool
    let showPodcastSubscribeButton: Bool
    let showEpisodeAddButton: Bool
    let isSelectionEnabled: Bool
    let episodeAddAction: (() -> Void)?
    let cellStyle: ListCellButtonStyle
    let action: (() -> Void)?

    init(episode: EpisodeSearchResult?, result: PodcastFolderSearchResult?, played: Bool = false, showDivider: Bool = true, showPodcastSubscribeButton: Bool = true, showEpisodeAddButton: Bool = false, episodeAddAction: (() -> Void)? = nil, isSelectionEnabled: Bool = true, cellStyle: ListCellButtonStyle = .init(), action: (() -> Void)? = nil) {
        self.played = episode != nil && played
        self.showDivider = showDivider
        self.showPodcastSubscribeButton = showPodcastSubscribeButton
        self.showEpisodeAddButton = showEpisodeAddButton
        self.isSelectionEnabled = isSelectionEnabled
        self.episodeAddAction = episodeAddAction
        self.cellStyle = cellStyle
        self._model = StateObject<SearchResultCellModel>(wrappedValue: SearchResultCellModel(episode: episode, podcastFolder: result))
        self.action = action
    }

    var episodeStateIcon: String? {
        guard let episode = model.episode else { return nil }
        switch episode.state {
        case .normal:
            return nil
        case .archived:
            return "list_archived"
        case .unavailable:
            return "option-cross-circle"
        }
    }

    var episodeStateText: String? {
        guard let episode = model.episode else { return nil }
        switch episode.state {
        case .normal:
            return nil
        case .archived:
            return L10n.podcastArchived
        case .unavailable:
            return L10n.podcastUnavailable
        }
    }

    var body: some View {
        Group {
            if isSelectionEnabled {
                Button(action: triggerSelectionAction) {
                    cellContent
                }
                .buttonStyle(cellStyle)
            } else {
                cellContent
                    .background(disabledBackgroundColor)
            }
        }
    }

    private func performDefaultAction() {
        if let episode = model.episode {
            NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid, NavigationManager.podcastKey: episode.podcastUuid])
            searchHistory.add(episode: episode)
            searchAnalyticsHelper.trackResultTapped(episode)
        } else if let result = model.podcastFolder {
            result.navigateTo()
            searchHistory.add(podcast: result)
            searchAnalyticsHelper.trackResultTapped(result)
        }
    }
}

private extension SearchResultCell {
    var cellContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                (model.episode?.podcastUuid ?? model.podcastFolder?.uuid).map {
                    SearchEntryImage(uuid: $0, kind: model.podcastFolder?.kind)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let episode = model.episode {
                        Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase)
                            .font(style: .footnote, weight: .bold)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        Text(episode.title)
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                            .lineLimit(2)
                        HStack(spacing: 4) {
                            if let icon = episodeStateIcon {
                                Image(icon)
                                    .renderingMode(.template)
                            }
                            if let stateText = episodeStateText {
                                Text(stateText)
                                Text("•")
                            }
                            Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration ?? 0)))
                        }
                        .font(style: .caption, weight: .semibold)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        .lineLimit(1)
                    } else if let result = model.podcastFolder {
                        Text(result.titleToDisplay)
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                            .lineLimit(2)
                        Text(subtitle(for: result))
                            .font(style: .caption, weight: .semibold)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .lineLimit(1)
                    }
                }
                .allowsHitTesting(false)
                Spacer()
                if model.episode != nil && model.episode?.state != .unavailable {
                    if played {
                        Image("list_played", bundle: nil)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(AppTheme.episodeCellPlayedIndicatorColor().color)
                            .frame(width: 48, height: 48)
                    } else if FeatureFlag.searchImprovements.enabled && !showEpisodeAddButton {
                        EpisodeActionButton(model: self.model)
                            .frame(width: 48, height: 48)
                    }
                    if showEpisodeAddButton {
                        Button(action: {
                            (episodeAddAction ?? action)?()
                        }) {
                            Image("plus-circle")
                                .resizable()
                                .renderingMode(.template)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 32)
                        .foregroundColor(theme.primaryInteractive01)
                    }
                } else if showPodcastSubscribeButton, let result = model.podcastFolder, result.kind == .podcast {
                    SubscribeButtonView(podcastUuid: result.uuid, source: searchAnalyticsHelper.source)
                }
            }
            .opacity(played || model.episode?.state.isNormal == false ? 0.5 : 1.0)
            if showDivider {
                ThemedDivider()
            }
        }
        .padding(FeatureFlag.searchImprovements.enabled ? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) : EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 8))
    }

    func triggerSelectionAction() {
        if let action {
            action()
        } else {
            performDefaultAction()
        }
    }

    var disabledBackgroundColor: Color {
        AppTheme.colorForStyle(cellStyle.backgroundStyle, themeOverride: theme.activeTheme).color
    }

    func subtitle(for result: PodcastFolderSearchResult) -> String {
        if result.kind == .folder {
            guard let folder = DataManager.sharedManager.findFolder(uuid: result.uuid) else {
                return L10n.folder
            }
            let count = DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
            return L10n.podcastCount(count)
        }

        return result.authorToDisplay
    }
}

extension PodcastFolderSearchResult {
    var titleToDisplay: String {
        title ?? ""
    }

    var authorToDisplay: String {
        author ?? ""
    }
}

struct EpisodeActionButton: UIViewRepresentable {

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: SearchResultCellModel

    func makeUIView(context: Context) -> MainEpisodeActionView {
        let view = MainEpisodeActionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    func updateUIView(_ view: MainEpisodeActionView, context: Context) {
        guard let episodeUUID = model.episode?.uuid else {
            return
        }
        let episode: BaseEpisode
        if let realEpisode = model.realEpisode {
            episode = realEpisode
        } else {
            episode = Episode()
            episode.uuid = episodeUUID
        }
        episode.uuid = episodeUUID
        view.delegate = model
        view.populateFrom(episode: episode)
        view.tintColor = AppTheme.colorForStyle(.primaryIcon01, themeOverride: theme.activeTheme)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MainEpisodeActionView, context: Context) -> CGSize? {
        // Use the proposal, uiView's intrinsic size, or custom logic
        if let width = proposal.width, let height = proposal.height {
            return CGSize(width: width, height: height)
        }
        // Or, to use the UIKit view's intrinsic content size:
        return uiView.intrinsicContentSize
    }
}
