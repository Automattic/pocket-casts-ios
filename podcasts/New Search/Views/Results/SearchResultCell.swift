import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI
import Combine

class SearchResultCellModel: ObservableObject, MainEpisodeActionViewDelegate {

    var episode: EpisodeSearchResult?
    var podcastFolder: PodcastFolderSearchResult?
    private(set) var realEpisode: BaseEpisode?

    @Published var refreshTrigger: Bool = true

    init(episode: EpisodeSearchResult?, podcastFolder: PodcastFolderSearchResult?) {
        self.episode = episode
        self.podcastFolder = podcastFolder
        setupObservers()
    }

    func playTapped() {
        guard let episode else {
            return
        }
        PlaybackManager.shared.playEpisodeSearchResult(episode)
    }

    func pauseTapped() {
        PlaybackActionHelper.pause()
    }

    func downloadTapped() {}

    func stopDownloadTapped() {}

    func errorTapped() {}

    func waitingForWifiTapped() {}

    private var cancellables = Set<AnyCancellable>()

    private func setupObservers() {
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackEnded),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused),
        )
        .receive(on: OperationQueue.main)
        .sink(receiveValue: { [unowned self] _ in
            self.refreshTrigger.toggle()
        })
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackPositionSaved)
        .receive(on: OperationQueue.main)
        .sink(receiveValue: { [unowned self] notification in
            guard let episodeUUID = notification.object as? String,
                  episodeUUID == episode?.uuid,
                  let realEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUUID) else {
                return
            }
            self.realEpisode = realEpisode
            self.refreshTrigger.toggle()
        })
        .store(in: &cancellables)
    }
}

struct SearchResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @StateObject var model: SearchResultCellModel

    let played: Bool
    let showDivider: Bool
    let cellStyle: ListCellButtonStyle

    init(episode: EpisodeSearchResult?, result: PodcastFolderSearchResult?, played: Bool = false, showDivider: Bool = true, cellStyle: ListCellButtonStyle = .init()) {
        self.played = episode != nil && played
        self.showDivider = showDivider
        self.cellStyle = cellStyle
        self._model = StateObject<SearchResultCellModel>(wrappedValue: SearchResultCellModel(episode: episode, podcastFolder: result))
    }

    var body: some View {
        ZStack {
            Button(action: {
                if let episode = model.episode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid, NavigationManager.podcastKey: episode.podcastUuid])
                    searchHistory.add(episode: episode)
                    searchAnalyticsHelper.trackResultTapped(episode)
                } else if let result = model.podcastFolder {
                    result.navigateTo()
                    searchHistory.add(podcast: result)
                    searchAnalyticsHelper.trackResultTapped(result)
                }
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(cellStyle)

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
                            Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration ?? 0)))
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        } else if let result = model.podcastFolder {
                            Text(result.titleToDisplay)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(result.kind == .folder ? L10n.folder : result.authorToDisplay)
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        }
                    }
                    .allowsHitTesting(false)
                    Spacer()
                    if model.episode != nil {
                        if played {
                            Image("list_played", bundle: nil)
                                .renderingMode(.template)
                                .foregroundStyle(AppTheme.episodeCellPlayedIndicatorColor().color)
                        } else if FeatureFlag.searchImprovements.enabled {
                            EpisodeActionButton(model: self.model)
                                .frame(width: 44, height: 44)
                        }
                    } else if let result = model.podcastFolder, result.kind == .podcast {
                        SubscribeButtonView(podcastUuid: result.uuid, source: searchAnalyticsHelper.source)
                    }
                }
                .opacity(played ? 0.5 : 1.0)
                if showDivider {
                    ThemedDivider()
                }
            }
            .padding(FeatureFlag.searchImprovements.enabled ? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) : EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 8))
        }
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
