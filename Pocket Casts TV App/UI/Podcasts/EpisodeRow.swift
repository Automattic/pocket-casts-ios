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

    @State var model: EpisodeRowViewModel
    var isActive: Bool?

    @Environment(\.isFocused) private var isFocused: Bool

    init(model: EpisodeRowViewModel, isActive: Bool? = nil) {
        self.model = model
        self.isActive = isActive
    }

    private var isHighlighted: Bool {
        isActive ?? isFocused
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
                Text(model.displayDate)
                    .font(.caption)
                    .foregroundColor(isHighlighted ? .textSecondaryActive : .textSecondary)
                Text(model.episode.displayableTitle())
                    .font(.body)
                    .foregroundColor(isHighlighted ? .textPrimaryActive : .textPrimary)
                    .lineLimit(2)
                Text(model.displayDuration)
                    .font(.caption)
                    .foregroundColor(isHighlighted ? .textSecondaryActive : .textSecondary)
            }
            Spacer()
        }
        .padding(24)
        .background(isHighlighted ? Color.backgroundActive : Color.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MoreButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    private enum Layout {
        static let size = CGFloat(72)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .frame(width: Layout.size, height: Layout.size)
            .background(isFocused ? Color.backgroundActive : Color.backgroundOverlay)
            .foregroundColor(isFocused ? .textPrimaryActive : .textPrimary)
            .clipShape(Circle())
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct EpisodeRowWithActions: View {

    enum Context {
        case `default`
        case upNext
    }

    let model: EpisodeRowViewModel
    var context: Context = .default

    @FocusState private var focusedElement: FocusElement?
    @State private var isPlaying = false
    @State private var isShowingActions = false
    @State private var restoreFocus = false

    private enum FocusElement: Hashable {
        case episode
        case more
    }

    private enum Layout {
        static let spacing = CGFloat(32)
    }

    private var shouldShowMoreButton: Bool {
        focusedElement != nil || isShowingActions || restoreFocus
    }

    private var isEpisodeFocused: Bool {
        focusedElement == .episode
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch context {
        case .default:
            Button(L10n.playNextInUpNext) {}
            Button(L10n.playLastInUpNext) {}
            Button(L10n.markPlayed) {}
            Button(L10n.archive) {}
        case .upNext:
            Button(L10n.playNext) {}
            Button(L10n.playLast) {}
            Button(L10n.removeFromUpNext) {}
        }
        Button(L10n.tvEpisodeInfo) {}
    }

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Button {
                isPlaying = true
                model.play()
            } label: {
                EpisodeRow(model: model, isActive: isEpisodeFocused)
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
        .defaultFocus($focusedElement, .episode)
        .animation(.easeInOut(duration: 0.2), value: shouldShowMoreButton)
        .onChange(of: isShowingActions) { _, showing in
            guard !showing else { return }
            DispatchQueue.main.async {
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
        .confirmationDialog(model.displayTitle, isPresented: $isShowingActions) {
            actionButtons
        }
    }
}

#Preview {
    EpisodeRowWithActions(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!))
    .environment(AppCoordinator())
    .environment(MainTabRouter())
}
