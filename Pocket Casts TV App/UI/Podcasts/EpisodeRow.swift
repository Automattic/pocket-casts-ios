import SwiftUI
import PocketCastsUtils

struct EpisodeRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct EpisodeRow: View {

    let episode: MockEpisode
    var isActive: Bool?

    @Environment(\.isFocused) private var isFocused: Bool

    private var isHighlighted: Bool {
        isActive ?? isFocused
    }

    enum Layout {
        static let episodeImageSize = CGFloat(124)
    }

    func displayDate(for date: Date) -> String {
        let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase
        return episodeDate
    }

    func displayDuration(for time: Double) -> String {
        let time = TimeFormatter.shared.multipleUnitFormattedShortTime(time: time)
        return time
    }

    var body: some View {
        HStack(spacing: 24) {
            Image(episode.image)
                .resizable()
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading) {
                Text(displayDate(for: episode.publishedDate))
                    .font(.caption)
                    .foregroundColor(isHighlighted ? .textSecondaryActive : .textSecondary)
                Text(episode.title)
                    .font(.body)
                    .foregroundColor(isHighlighted ? .textPrimaryActive : .textPrimary)
                    .lineLimit(2)
                Text(displayDuration(for: episode.duration))
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

    let episode: MockEpisode
    var podcastTitle: String?
    var podcastDescription: String?

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

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Button {
                isPlaying = true
            } label: {
                EpisodeRow(episode: episode, isActive: isEpisodeFocused)
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
            if !showing {
                DispatchQueue.main.async {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        focusedElement = .more
                        restoreFocus = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            EpisodePlayerView(
                episode: episode,
                podcastTitle: podcastTitle,
                podcastDescription: podcastDescription
            )
            .ignoresSafeArea()
        }
        .confirmationDialog(episode.title, isPresented: $isShowingActions) {
            Button(L10n.playNextInUpNext) {}
            Button(L10n.playLastInUpNext) {}
            Button(L10n.markPlayed) {}
            Button(L10n.archive) {}
            Button(L10n.tvEpisodeInfo) {}
        }
    }
}

#Preview {
    EpisodeRowWithActions(
        episode: MockData.makePodcasts().first!.episodes.first!,
        podcastTitle: "The Daily"
    )
    .environment(AppCoordinator())
    .environment(MainTabRouter())
}
