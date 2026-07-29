import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct BookmarkRow<Style: BookmarksStyle>: View {
    @EnvironmentObject var viewModel: BookmarkListViewModel
    @StateObject private var rowModel = BookmarkRowViewModel()

    private let bookmark: Bookmark

    @ObservedObject private var style: Style
    @State private var highlighted = false

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 56

    init(bookmark: Bookmark, style: Style) {
        self.bookmark = bookmark
        self.style = style
    }

    var body: some View {
        let selected = viewModel.isSelected(bookmark)
        MultiSelectRow(showSelectButton: viewModel.isMultiSelecting, selected: selected) {
            HStack(spacing: RowConstants.spacing) {
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
        .padding(.horizontal, RowConstants.horizontalPadding)
        .padding(.vertical, RowConstants.verticalPadding)
        .animation(.default, value: viewModel.isMultiSelecting)

        // Display a highlight when tapped, or the row is selected
        .background((!selected && highlighted) ? style.rowHighlight : nil)
        .animation(.linear, value: highlighted)

        .background(selected ? style.rowSelected : nil)
        .animation(.linear, value: selected)

        .task(id: bookmark.id) {
            await rowModel.configure(with: bookmark)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let episode = rowModel.episode {
            EpisodeImage(episode: episode)
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        } else {
            Rectangle()
                .foregroundColor(style.tertiaryText)
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

                Text(bookmark.title)
                    .foregroundStyle(style.primaryText)
                    .font(style: .subheadline, weight: .medium)

                Text(subtitle)
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

    private var subtitle: String {
        DateFormatter.localizedString(from: bookmark.created, dateStyle: .medium, timeStyle: .short)
    }

    /// Displays the play button view, and adds the action to it
    private var playButtonView: some View {
        let isLoading = viewModel.loadingBookmarkUuid == bookmark.uuid

        return PlayButton(title: TimeFormatter.shared.playTimeFormat(time: bookmark.time), isLoading: isLoading, style: style).buttonize {
            viewModel.bookmarkPlayTapped(bookmark)
        } customize: { config in
            config.label
                .opacity(config.isPressed ? 0.9 : 1)
                .applyButtonEffect(isPressed: config.isPressed)
        }
        .opacity(viewModel.isMultiSelecting ? 0.3 : 1)
        .disabled(viewModel.isMultiSelecting || isLoading)
    }

    // MARK: - Play Button View
    private struct PlayButton<ButtonStyle: BookmarksStyle>: View {
        let title: String
        let isLoading: Bool
        @ObservedObject var style: ButtonStyle

        var body: some View {
            HStack(spacing: 10) {
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .fixedSize()

                Image("bookmarks-icon-play")
                    .renderingMode(.template)
                    .opacity(isLoading ? 0 : 1)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(style.playButtonText)
                                .scaleEffect(0.8)
                        }
                    }
            }
            .foregroundStyle(style.playButtonText)
            .padding(.horizontal, RowConstants.horizontalPadding)
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
    static let horizontalPadding = 16.0
    static let spacing = 12.0
    static let verticalPadding = 12.0
    static let playButtonVerticalPadding = 8.0
}
