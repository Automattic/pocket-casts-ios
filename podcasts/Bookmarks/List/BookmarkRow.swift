import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct BookmarkRow: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var viewModel: BookmarkListViewModel

    private let bookmark: BookmarkManager.Bookmark

    private let title: String
    private let subtitle: String
    private let playButton: String

    @State private var higlighted = false

    init(bookmark: BookmarkManager.Bookmark) {
        self.bookmark = bookmark

        let title = bookmark.title?.isEmpty == false ? bookmark.title : nil
        let displayTime = TimeFormatter.shared.playTimeFormat(time: bookmark.time)

        // Default to showing the display time if we don't have a title
        self.title = title ?? displayTime
        self.playButton = title == nil ? L10n.play : displayTime

        self.subtitle = DateFormatter.localizedString(from: bookmark.createdDate,
                                                      dateStyle: .medium,
                                                      timeStyle: .short)
    }

    var body: some View {
        HStack {
            detailsView
            playButtonView
        }
        .padding(Constants.padding)

        // Display a highlight when tapped
        .background(higlighted ? theme.playerContrast05 : nil)
        .animation(.linear, value: higlighted)
    }

    /// Displays a title and subtitle
    private var detailsView: some View {
        NonBlockingLongPressView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .foregroundStyle(theme.playerContrast01)
                    .font(style: .subheadline, weight: .medium)

                Text(subtitle)
                    .foregroundStyle(theme.playerContrast02)
                    .font(style: .caption, weight: .semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } onTapped: {
            viewModel.bookmarkTapped(bookmark)
        } onPressed: { pressed in
            higlighted = pressed
        } onLongPressed: {
            /* not used yet */
        }
    }

    /// Displays the play button view, and adds the action to it
    private var playButtonView: some View {
        PlayButton(title: playButton).buttonize {
            viewModel.bookmarkPlayTapped(bookmark)
        } customize: { config in
            config.label
                .opacity(config.isPressed ? 0.9 : 1)
                .applyButtonEffect(isPressed: config.isPressed)
        }
    }

    // MARK: - Play Button View
    private struct PlayButton: View {
        @EnvironmentObject var theme: Theme

        let title: String

        var body: some View {
            HStack(spacing: 10) {
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .fixedSize()

                Image("bookmarks-icon-play")
                    .renderingMode(.template)
            }
            .foregroundStyle(theme.playerBackground01)
            .padding(.horizontal, Constants.padding)
            .padding(.vertical, Constants.playButtonVerticalPadding)
            .background(theme.playerContrast01)
            .cornerRadius(.infinity) // Always rounded
        }
    }

    private enum Constants {
        static let padding = 16.0
        static let playButtonVerticalPadding = 8.0
    }
}
