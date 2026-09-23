import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel
import PocketCastsServer

struct EpisodeRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct EpisodeRow: View {

    let model: EpisodeRowViewModel
    var isActive: Bool?
    var showEpisodeNotesImage: Bool

    @Environment(\.isFocused) private var isFocused: Bool

    init(model: EpisodeRowViewModel, isActive: Bool? = nil, showEpisodeNotesImage: Bool = false) {
        self.model = model
        self.isActive = isActive
        self.showEpisodeNotesImage = showEpisodeNotesImage
    }

    enum Layout {
        static let episodeImageSize = CGFloat(124)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if showEpisodeNotesImage {
            EpisodeArtworkView(model: EpisodeArtworkViewModel(episode: model.episode, size: .list, showEpisodeNotesImage: showEpisodeNotesImage))
        } else {
            if let uuid = model.podcastUuid {
                PodcastImage(uuid: uuid, size: .list)
            } else {
                Image(ImageResource.pcLogo)
                   .accessibilityHidden(true)
            }
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            thumbnail
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if model.isVideo {
                        Image(systemName: "play.rectangle.fill")
                            .font(.caption)
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                            .accessibilityLabel(L10n.filterMediaTypeVideo)
                    }
                    Text(model.displayDate)
                        .font(.caption)
                        .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                }
                Text(model.episode.displayableTitle())
                    .font(.body)
                    .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(isInProgress ? model.timeLeft : model.displayDuration)
                        .font(.caption)
                        .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    if isInProgress {
                        let trackColor = (isFocused ? Color.pcTextSecondaryActive : Color.pcTextSecondary)
                        RoundProgressView(trackColor: trackColor, progress: model.progress)
                            .frame(width: 96, height: 6)
                            .padding(.leading, 8)
                    } else if model.isPlayed {
                        Image(systemName: "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    }
                }
            }
            Spacer()
        }
        .padding(32)
        .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusedCardDepth(isFocused: isFocused, cornerRadius: 12, style: .content)
        .opacity(archivedOpacity)
        .animation(.easeInOut(duration: 0.15), value: archivedOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "\(model.episode.displayableTitle()) \(model.episode.accessibilityDisplayableInfo()), \(model.displayDate)"
    }

    private var isInProgress: Bool {
        model.episode.inProgress()
    }

    private var archivedOpacity: Double {
        guard model.isArchived else { return 1.0 }
        return isFocused ? 1.0 : 0.3
    }
}

struct MoreButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    fileprivate enum Layout {
        static let size = CGFloat(72)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .frame(width: Layout.size, height: Layout.size)
            .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundOverlay)
            .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
            .clipShape(Circle())
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

/// Identifies which element of which episode row holds focus. Lifted out of the
/// row (where it used to be per-row private `@FocusState` plus a per-row
/// `defaultFocus`) into a single state the enclosing list owns and keys by
/// episode UUID. This lets tvOS recover focus to a neighbouring row when the
/// focused row is removed (archive, remove-from-Up-Next, …) instead of dropping
/// focus entirely and recursing over the orphaned cell container.
enum EpisodeRowFocus: Hashable {
    case episode(String)
    case more(String)

    var episodeID: String {
        switch self {
        case .episode(let id), .more(let id):
            return id
        }
    }
}

struct EpisodeRowWithActions: View {

    let model: EpisodeRowViewModel
    var context: EpisodeActionContext = .other(showGoToPodcast: false)
    var showEpisodeNotesImage: Bool = false
    @FocusState.Binding var focus: EpisodeRowFocus?
    var customPlayDisplayAction: (() -> ())? = nil
    var detailsDismissed: (() -> ())? = nil

    @State private var isPlaying = false
    @State private var isShowingActions = false
    @State private var isShowingShowNotes = false
    @State private var restoreFocus = false

    private enum Layout {
        static let spacing = CGFloat(32)
    }

    private var shouldShowMoreButton: Bool {
        focus?.episodeID == model.id || restoreFocus
    }

    private var isEpisodeFocused: Bool {
        focus == .episode(model.id)
    }

    @Environment(\.isFocused) private var isFocused: Bool

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Button {
                if let customPlayDisplayAction {
                    customPlayDisplayAction()
                } else {
                    isPlaying = true
                }
                model.play()
            } label: {
                HStack(spacing: 0) {
                    EpisodeRow(model: model, isActive: isEpisodeFocused, showEpisodeNotesImage: showEpisodeNotesImage)
                    Spacer()
                        .frame(width: !shouldShowMoreButton ? Layout.spacing + MoreButtonStyle.Layout.size : 0)
                }
                .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(EpisodeRowButtonStyle())
            .focused($focus, equals: .episode(model.id))

            if shouldShowMoreButton {
                Button {
                    restoreFocus = true
                    isShowingActions = true
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(MoreButtonStyle())
                .focused($focus, equals: .more(model.id))
                .accessibilityLabel(L10n.accessibilityMoreActions)
                .transition(.opacity.combined(with: .scale(scale: 0.8)).animation(.easeOut(duration: 0.2).delay(0.15)))
            }
        }
        .contextMenu {
            EpisodeActionButtons(model: model, context: context, isShowingShowNotes: $isShowingShowNotes)
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowMoreButton)
        .onChange(of: isShowingActions) { _, showing in
            guard !showing else { return }
            // tvOS runs its own focus restoration as the dialog animates out,
            // and it lands focus on whatever surrounds the row (often the tab
            // bar). Wait for that pass to settle before pulling focus back to
            // the ellipsis ourselves, otherwise our assignment is overwritten.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                // If the action removed this row the list has already moved focus
                // to a neighbour — only restore the ellipsis when focus was simply
                // dropped or is still on us, never fight the hand-off.
                guard focus == nil || focus?.episodeID == model.id else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    focus = .more(model.id)
                    restoreFocus = false
                }
            }
        }
        .onChange(of: isShowingShowNotes) { _, showing in
            if !showing {
                detailsDismissed?()
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            NowPlayingView()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingShowNotes) {
            EpisodeShowNotesView(episode: model.episode, podcast: model.podcast)
        }
        .confirmationDialog(model.displayTitle, isPresented: $isShowingActions) {
            EpisodeActionButtons(model: model, context: context, isShowingShowNotes: $isShowingShowNotes)
        }
    }
}

enum EpisodeActionContext {
    case other(showGoToPodcast: Bool)
    case upNext
}

struct EpisodeActionButtons: View {

    let model: EpisodeRowViewModel
    var context: EpisodeActionContext = .other(showGoToPodcast: false)
    @Binding var isShowingShowNotes: Bool

    @Environment(\.requireAccount) private var requireAccount

    @Environment(StackPath.self) private var stackPath: StackPath?

    var body: some View {
        Group {
            if model.podcastUuid != nil {
                Button(L10n.tvEpisodeShowNotesAction) { isShowingShowNotes = true }
            }
            switch context {
            case .other(let showGoToPodcast):
                if showGoToPodcast {
                    Button(L10n.goToPodcast) { goToPodcast() }
                }
                Button(L10n.playNextInUpNext) { requireAccount { model.playNext() } }
                Button(L10n.playLastInUpNext) { requireAccount { model.playLast() } }
                Button(model.isPlayed ? L10n.markUnplayed : L10n.markPlayed) { requireAccount { model.isPlayed ? model.markAsUnplayed() : model.markAsPlayed() } }
                if model.canArchive {
                    Button(model.isArchived ? L10n.unarchive : L10n.archive) { requireAccount { model.isArchived ? model.unarchive() : model.archive() } }
                }
            case .upNext:
                if model.podcast != nil {
                    Button(L10n.goToPodcast) { goToPodcast() }
                }
                Button(L10n.playNext) { requireAccount { model.playNext() } }
                Button(L10n.playLast) { requireAccount { model.playLast() } }
                Button(L10n.removeFromUpNext) { model.removeFromUpNext() }
            }
        }.onAppear {
            Analytics.track(.episodeActionsShown)
        }
    }

    /// Pushes the episode's podcast onto the navigation stack, preferring the
    /// loaded `Podcast` and falling back to a `DiscoverPodcast` built from the
    /// episode's podcast UUID when only the episode is known.
    private func goToPodcast() {
        if let podcast = model.podcast {
            stackPath?.navigationPath.append(podcast)
        } else if let episode = model.episode as? Episode {
            var podcast = DiscoverPodcast()
            podcast.uuid = episode.podcastUuid
            stackPath?.navigationPath.append(podcast)
        }
    }
}

private struct EpisodeContextMenuModifier: ViewModifier {

    let model: EpisodeRowViewModel
    var context: EpisodeActionContext

    @State private var isShowingShowNotes = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                EpisodeActionButtons(model: model, context: context, isShowingShowNotes: $isShowingShowNotes)
                    .remotePlayPause()
            }
            .sheet(isPresented: $isShowingShowNotes) {
                EpisodeShowNotesView(episode: model.episode, podcast: model.podcast)
            }
    }
}

extension View {
    func episodeContextMenu(model: EpisodeRowViewModel, context: EpisodeActionContext = .other(showGoToPodcast: false)) -> some View {
        modifier(EpisodeContextMenuModifier(model: model, context: context))
    }
}

/// An episode loaded from its UUIDs, ready to act on or present show notes for.
struct DiscoveryLoadedEpisode: Identifiable {
    let episode: Episode
    let podcast: Podcast?
    var id: String { episode.uuid }
}

/// Context menu for episodes known only by their UUIDs (Discover, Search). The
/// `Episode` is loaded lazily the first time an action runs; show notes are
/// surfaced through `showNotesEpisode` so the presenting view owns the sheet.
struct DiscoveryEpisodeMenuButtons: View {

    let podcastUuid: String
    let episodeUuid: String
    @Binding var showNotesEpisode: DiscoveryLoadedEpisode?

    var podcast: DiscoverPodcast?

    var podcastCallback: (()->())? = nil

    @Environment(\.requireAccount) private var requireAccount

    @Environment(StackPath.self) private var stackPath: StackPath?

    var body: some View {
        Button(L10n.tvEpisodeShowNotesAction) { load { showNotesEpisode = $0 } }
        Button(L10n.goToPodcast) { goToPodcast() }
        Button(L10n.playNextInUpNext) { requireAccount { load { EpisodeUpNextActions.playNext($0.episode) } } }
        Button(L10n.playLastInUpNext) { requireAccount { load { EpisodeUpNextActions.playLast($0.episode) } } }
    }

    private func load(_ action: @escaping (DiscoveryLoadedEpisode) -> Void) {
        Task {
            guard let result = await TVDataManager.shared.loadEpisode(podcastUuid: podcastUuid, episodeUuid: episodeUuid) else {
                ToastManager.shared.show(L10n.playbackFailed)
                return
            }
            action(DiscoveryLoadedEpisode(episode: result.episode, podcast: result.podcast))
        }
    }

    private func goToPodcast() {
        var podcast = DiscoverPodcast()
        podcast.uuid = podcastUuid
        stackPath?.navigationPath.append(podcast)
    }
}

private struct DiscoveryEpisodeContextMenuModifier: ViewModifier {

    let podcastUuid: String
    let episodeUuid: String

    @State private var showNotesEpisode: DiscoveryLoadedEpisode?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                DiscoveryEpisodeMenuButtons(podcastUuid: podcastUuid, episodeUuid: episodeUuid, showNotesEpisode: $showNotesEpisode, podcast: nil)
            }
            .sheet(item: $showNotesEpisode) { episode in
                EpisodeShowNotesView(episode: episode.episode, podcast: episode.podcast)
            }
    }
}

extension View {
    func discoveryEpisodeContextMenu(podcastUuid: String, episodeUuid: String) -> some View {
        modifier(DiscoveryEpisodeContextMenuModifier(podcastUuid: podcastUuid, episodeUuid: episodeUuid))
    }
}

#Preview {
    @Previewable @FocusState var focus: EpisodeRowFocus?
    EpisodeRowWithActions(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!, source: .unknown), focus: $focus)
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
}
