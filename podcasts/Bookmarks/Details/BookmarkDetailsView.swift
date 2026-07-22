import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

/// A single bookmark in full: the episode it was taken from, and the transcript passage
/// it captured.
struct BookmarkDetailsView: View {
    @ObservedObject var viewModel: BookmarkDetailsViewModel

    @EnvironmentObject private var theme: Theme

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 56

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                content
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01.ignoresSafeArea())
        .miniPlayerSafeAreaInset()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                viewModel.podcastTitle.map {
                    Text($0)
                        .font(style: .footnote, weight: .medium)
                        .foregroundStyle(theme.primaryText02)
                        .lineLimit(1)
                }

                viewModel.episode.map {
                    Text($0.displayableTitle())
                        .font(style: .subheadline, weight: .semibold)
                        .foregroundStyle(theme.primaryText01)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            playButton
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let episode = viewModel.episode {
            EpisodeImage(episode: episode)
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(theme.primaryUi05)
                .frame(width: imageSize, height: imageSize)
        }
    }

    private var playButton: some View {
        HStack(spacing: 8) {
            Text(timestamp)
                .font(style: .subheadline, weight: .medium)
                .fixedSize()

            Image("bookmarks-icon-play")
                .renderingMode(.template)
        }
        .foregroundStyle(theme.primaryInteractive02)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.primaryInteractive01)
        .clipShape(Capsule())
        .buttonize {
            viewModel.onPlay()
        }
        .accessibilityLabel(L10n.play)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(created)
                .font(style: .footnote, weight: .medium)
                .foregroundStyle(theme.primaryText02)

            Text(viewModel.bookmark.title)
                .font(size: 22, style: .title3, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .padding(.bottom, 4)

            Text(timestamp)
                .font(style: .footnote, weight: .medium)
                .foregroundStyle(theme.primaryText02)

            viewModel.passage.map {
                Text($0)
                    .font(size: BookmarkTranscriptStyle.fontSize, style: .body, design: .serif)
                    .lineSpacing(BookmarkTranscriptStyle.lineSpacing)
                    .foregroundStyle(theme.primaryText02)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timestamp: String {
        TimeFormatter.shared.playTimeFormat(time: viewModel.bookmark.time)
    }

    private var created: String {
        DateFormatter.localizedString(from: viewModel.bookmark.created, dateStyle: .medium, timeStyle: .short)
    }
}

// MARK: - Preview

struct BookmarkDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookmarkDetailsView(viewModel: .init(bookmark: Self.previewBookmark(title: "Why admissions feel like a lottery",
                                                                                time: 1390,
                                                                                created: .now),
                                                 passage: previewPassage,
                                                 episode: previewEpisode,
                                                 podcastTitle: "Radio Atlantic",
                                                 bookmarkManager: .init()))
        }
        .setupDefaultEnvironment()
    }

    private static var previewEpisode: Episode {
        let episode = Episode()
        episode.title = "Higher Educations Identify Crisis"
        return episode
    }

    private static let previewPassage = """
    that's the thing about selective admissions — the difference between the kid who gets in \
    and the kid who doesn't is often basically noise. Right, and that's why some researchers \
    have floated the lottery idea. You set a bar for who's qualified, and past that, you just \
    draw names. It sounds radical, but it's arguably more honest than pretending there's a \
    meaningful distinction between applicant 1,800 and applicant 2,100.
    """
}
