import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct BookmarkRow<Style: BookmarksStyle>: View {
    @EnvironmentObject var listViewModel: BookmarkListViewModel
    @State private var viewModel: BookmarkRowViewModel

    private let bookmark: Bookmark

    @ObservedObject private var style: Style
    @State private var highlighted = false

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 56

    init(bookmark: Bookmark, style: Style) {
        self.bookmark = bookmark
        self.style = style
        self._viewModel = State(initialValue: BookmarkRowViewModel(bookmark: bookmark))
    }

    var body: some View {
        let selected = listViewModel.isSelected(bookmark)
        MultiSelectRow(showSelectButton: listViewModel.isMultiSelecting, selected: selected) {
            HStack(spacing: RowConstants.spacing) {
                imageView
                detailsView
                playButtonView
            }
        } onSelectionToggled: {
            withAnimation {
                listViewModel.toggleSelected(bookmark)
            }
        }
        .selectButtonStyle(tintColor: style.selectButton, checkColor: style.selectCheck, strokeColor: style.selectButtonStroke)
        .padding(.horizontal, RowConstants.horizontalPadding)
        .padding(.vertical, RowConstants.verticalPadding)
        .contentShape(Rectangle())
        .onTapGesture {
            listViewModel.tapped(item: bookmark)
        }
        .onLongPressGesture {
            listViewModel.longPressed(bookmark)
        } onPressingChanged: { pressed in
            highlighted = pressed
        }
        .animation(.default, value: listViewModel.isMultiSelecting)

        // Display a highlight when tapped, or the row is selected
        .background((!selected && highlighted) ? style.rowHighlight : nil)
        .animation(.linear, value: highlighted)

        .background(selected ? style.rowSelected : nil)
        .animation(.linear, value: selected)

        .task(id: bookmark.id) {
            await viewModel.configure(with: bookmark)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let episode = viewModel.episode {
            Button {
                listViewModel.episodeTapped(episode, for: bookmark)
            } label: {
                EpisodeImage(episode: episode)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        } else {
            Rectangle()
                .foregroundColor(style.tertiaryText)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        }
    }

    /// Displays a title and subtitle
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: viewModel.heading != nil ? 4 : 8) {
            viewModel.heading.map {
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
    }

    private var subtitle: String {
        DateFormatter.localizedString(from: bookmark.created, dateStyle: .medium, timeStyle: .short)
    }

    /// Displays the play button view, and adds the action to it
    private var playButtonView: some View {
        let isLoading = listViewModel.loadingBookmarkUuid == bookmark.uuid
        let isMultiSelecting = listViewModel.isMultiSelecting

        return PlayButton(title: TimeFormatter.shared.playTimeFormat(time: bookmark.time), isLoading: isLoading, isCollapsed: isMultiSelecting, style: style).buttonize {
            listViewModel.bookmarkPlayTapped(bookmark)
        } customize: { config in
            config.label
                .opacity(config.isPressed ? 0.9 : 1)
                .applyButtonEffect(isPressed: config.isPressed)
        }
        .disabled(isMultiSelecting || isLoading)
    }

    // MARK: - Play Button View
    private struct PlayButton<ButtonStyle: BookmarksStyle>: View {
        let title: String
        let isLoading: Bool
        let isCollapsed: Bool
        @ObservedObject var style: ButtonStyle

        var body: some View {
            HStack(spacing: 10) {
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .fixedSize()

                Image("bookmarks-icon-play")
                    .renderingMode(.template)
                    .opacity(isCollapsed || isLoading ? 0 : 1)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(style.playButtonText)
                                .scaleEffect(0.8)
                        }
                    }
            }
            .foregroundStyle(isCollapsed ? style.secondaryText : style.playButtonText)
            .padding(.horizontal, RowConstants.horizontalPadding)
            .padding(.vertical, RowConstants.playButtonVerticalPadding)
            .background(isCollapsed ? nil : style.playButtonBackground)
            .cornerRadius(.infinity) // Always rounded
            .overlay(
                isCollapsed ? nil : style.playButtonStroke.map {
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
