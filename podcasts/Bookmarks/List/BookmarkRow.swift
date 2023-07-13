import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct BookmarkRow: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var viewModel: BookmarkListViewModel

    private let bookmark: Bookmark

    private let title: String
    private let subtitle: String
    private let playButton: String

    @State private var highlighted = false

    init(bookmark: Bookmark) {
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
        let selected = viewModel.itemIsSelected(bookmark)
        MultiSelectRow(visible: viewModel.isMultiSelecting, selected: selected) {
            HStack {
                detailsView
                playButtonView
            }
        } onSelectionToggled: {
            withAnimation {
                viewModel.toggleItemSelected(bookmark)
            }
        }
        .rowStyle(tintColor: theme.playerContrast01, checkColor: theme.playerBackground01)
        .padding(Constants.padding)
        // Display a highlight when tapped, or the row is selected
        .background((highlighted || selected) ? theme.playerContrast05 : nil)
        .animation(.linear, value: highlighted)
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
            highlighted = pressed
        } onLongPressed: {
            withAnimation {
                viewModel.longPressed(bookmark)
            }
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
        .opacity(viewModel.isMultiSelecting ? 0.3 : 1)
        .disabled(viewModel.isMultiSelecting)
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
