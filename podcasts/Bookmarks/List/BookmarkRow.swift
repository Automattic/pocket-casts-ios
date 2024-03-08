import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct BookmarkRow<Style: BookmarksStyle>: View {
    @EnvironmentObject var viewModel: BookmarkListViewModel
    @ObservedObject var rowModel: BookmarkRowViewModel

    private let bookmark: Bookmark

    @ObservedObject private var style: Style
    @State private var highlighted = false

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 56

    init(bookmark: Bookmark, style: Style) {
        self.rowModel = .init(bookmark: bookmark)
        self.bookmark = bookmark
        self.style = style
    }

    var body: some View {
        let selected = viewModel.isSelected(bookmark)
        MultiSelectRow(showSelectButton: viewModel.isMultiSelecting, selected: selected) {
            HStack(spacing: RowConstants.padding) {
                imageView
                detailsView
                playButtonView
            }
        } onSelectionToggled: {
            withAnimation {
                viewModel.toggleSelected(bookmark)
            }
        }
        .selectButtonStyle(tintColor: style.selectButton, checkColor: style.selectCheck, strokeColor: style.selectButtonStroke)
        .padding(RowConstants.padding)
        .animation(.default, value: viewModel.isMultiSelecting)

        // Display a highlight when tapped, or the row is selected
        .background((!selected && highlighted) ? style.rowHighlight : nil)
        .animation(.linear, value: highlighted)

        .background(selected ? style.rowSelected : nil)
        .animation(.linear, value: selected)
    }

    private var imageView: some View {
        rowModel.episode.map {
            EpisodeImage(episode: $0)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        }
    }

    /// Displays a title and subtitle
    private var detailsView: some View {
        NonBlockingLongPressView {
            VStack(alignment: .leading, spacing: rowModel.heading != nil ? 4 : 8) {
                rowModel.heading.map {
                    Text($0)
                        .foregroundStyle(style.tertiaryText)
                        .font(style: .caption, weight: .semibold)
                        .lineLimit(1)
                }

                Text(rowModel.title)
                    .foregroundStyle(style.primaryText)
                    .font(style: .subheadline, weight: .medium)
                    .lineLimit(1)

                Text(rowModel.subtitle)
                    .foregroundStyle(style.tertiaryText)
                    .font(style: .caption, weight: .semibold)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } onTapped: {
            viewModel.tapped(item: bookmark)
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
        PlayButton(title: rowModel.playButton, style: style).buttonize {
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
    private struct PlayButton<Style: BookmarksStyle>: View {
        let title: String
        @ObservedObject var style: Style

        var body: some View {
            HStack(spacing: 10) {
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .fixedSize()

                Image("bookmarks-icon-play")
                    .renderingMode(.template)
            }
            .foregroundStyle(style.playButtonText)
            .padding(.horizontal, RowConstants.padding)
            .padding(.vertical, RowConstants.playButtonVerticalPadding)
            .background(style.playButtonBackground)
            .cornerRadius(.infinity) // Always rounded
            .overlay(
                style.playButtonStroke.map {
                    RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                        .inset(by: 1)
                        .stroke($0, lineWidth: 2)
                }
            )
        }
    }
}

private enum RowConstants {
    static let padding = 16.0
    static let playButtonVerticalPadding = 8.0
}
