import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

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

    @Environment(\.isFocused) private var isFocused: Bool

    init(model: EpisodeRowViewModel, isActive: Bool? = nil) {
        self.model = model
        self.isActive = isActive
    }

    enum Layout {
        static let episodeImageSize = CGFloat(124)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uuid = model.podcastUuid {
            PodcastImage(uuid: uuid, size: .list)
        } else {
            Image(ImageResource.pcLogo)
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            thumbnail
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading) {
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
                Text(model.displayDuration)
                    .font(.caption)
                    .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
            }
            Spacer()
        }
        .padding(32)
        .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusedCardDepth(isFocused: isFocused, cornerRadius: 12, style: .content)
        .opacity(archivedOpacity)
        .animation(.easeInOut(duration: 0.15), value: archivedOpacity)
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

struct EpisodeRowWithActions: View {

    let model: EpisodeRowViewModel
    var context: EpisodeActionContext = .default

    @FocusState private var focusedElement: FocusElement?
    @State private var isPlaying = false
    @State private var isShowingActions = false
    @State private var isShowingShowNotes = false
    @State private var restoreFocus = false

    private enum FocusElement: Hashable {
        case episode
        case more
    }

    private enum Layout {
        static let spacing = CGFloat(32)
    }

    private var shouldShowMoreButton: Bool {
        focusedElement != nil || restoreFocus
    }

    private var isEpisodeFocused: Bool {
        focusedElement == .episode
    }

    @Environment(\.isFocused) private var isFocused: Bool

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Button {
                isPlaying = true
                model.play()
            } label: {
                HStack(spacing: 0) {
                    EpisodeRow(model: model, isActive: isEpisodeFocused)
                    Spacer()
                        .frame(width: !shouldShowMoreButton ? Layout.spacing + MoreButtonStyle.Layout.size : 0)
                }
                .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(EpisodeRowButtonStyle())
            .focused($focusedElement, equals: .episode)

            if shouldShowMoreButton {
                Button {
                    restoreFocus = true
                    isShowingActions = true
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(MoreButtonStyle())
                .focused($focusedElement, equals: .more)
                .transition(.opacity.combined(with: .scale(scale: 0.8)).animation(.easeOut(duration: 0.2).delay(0.15)))
            }
        }
        .contextMenu {
            EpisodeActionButtons(model: model, context: context, isShowingShowNotes: $isShowingShowNotes)
        }
        .if(isFocused) { content in
            content.clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .defaultFocus($focusedElement, .episode)
        .animation(.easeInOut(duration: 0.2), value: shouldShowMoreButton)
        .onChange(of: isShowingActions) { _, showing in
            guard !showing else { return }
            // tvOS runs its own focus restoration as the dialog animates out,
            // and it lands focus on whatever surrounds the row (often the tab
            // bar). Wait for that pass to settle before pulling focus back to
            // the ellipsis ourselves, otherwise our assignment is overwritten.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    focusedElement = .more
                    restoreFocus = false
                }
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
    case `default`
    case upNext
}

struct EpisodeActionButtons: View {

    let model: EpisodeRowViewModel
    var context: EpisodeActionContext = .default
    @Binding var isShowingShowNotes: Bool

    @Environment(\.requireAccount) private var requireAccount

    var body: some View {
        if model.podcastUuid != nil {
            Button(L10n.tvEpisodeShowNotesAction) { isShowingShowNotes = true }
        }
        switch context {
        case .default:
            Button(L10n.playNextInUpNext) { requireAccount { model.playNext() } }
            Button(L10n.playLastInUpNext) { requireAccount { model.playLast() } }
            Button(L10n.markPlayed) { requireAccount { model.markAsPlayed() } }
            if model.canArchive {
                Button(model.isArchived ? L10n.unarchive : L10n.archive) { requireAccount { model.isArchived ? model.unarchive() : model.archive() } }
            }
        case .upNext:
            Button(L10n.playNext) { requireAccount { model.playNext() } }
            Button(L10n.playLast) { requireAccount { model.playLast() } }
            Button(L10n.removeFromUpNext) { model.removeFromUpNext() }
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
            }
            .sheet(isPresented: $isShowingShowNotes) {
                EpisodeShowNotesView(episode: model.episode, podcast: model.podcast)
            }
    }
}

extension View {
    func episodeContextMenu(model: EpisodeRowViewModel, context: EpisodeActionContext = .default) -> some View {
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

    @Environment(\.requireAccount) private var requireAccount

    var body: some View {
        Button(L10n.tvEpisodeShowNotesAction) { load { showNotesEpisode = $0 } }
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
}

private struct DiscoveryEpisodeContextMenuModifier: ViewModifier {

    let podcastUuid: String
    let episodeUuid: String

    @State private var showNotesEpisode: DiscoveryLoadedEpisode?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                DiscoveryEpisodeMenuButtons(podcastUuid: podcastUuid, episodeUuid: episodeUuid, showNotesEpisode: $showNotesEpisode)
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
    EpisodeRowWithActions(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!))
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
}
