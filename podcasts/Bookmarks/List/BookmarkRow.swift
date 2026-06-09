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
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    imageView
                    detailsView
                        .frame(maxWidth: .infinity, alignment: .leading)
                    playButton
                }

                if let transcriptText = rowModel.transcriptText {
                    Text(transcriptText)
                        .foregroundStyle(style.secondaryText)
                        .font(.footnote.italic())
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, imageSize + 14)
                        .padding(.top, 4)
                }
            }
        } onSelectionToggled: {
            withAnimation {
                viewModel.toggleSelected(bookmark)
            }
        }
        .selectButtonStyle(tintColor: style.selectButton, checkColor: style.selectCheck, strokeColor: style.selectButtonStroke)
        .padding(.vertical, 14)
        .background(selected ? style.rowSelected : (highlighted ? style.rowHighlight : Color.clear))
        .animation(.default, value: viewModel.isMultiSelecting)
        .animation(.linear, value: highlighted)
        .animation(.linear, value: selected)
    }

    @ViewBuilder
    private var imageView: some View {
        if let episode = rowModel.episode {
            EpisodeImage(episode: episode)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        } else {
            Rectangle()
                .foregroundColor(style.tertiaryText)
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
        }
    }

    private var detailsView: some View {
        NonBlockingLongPressView {
            VStack(alignment: .leading, spacing: 4) {
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

    private var playButton: some View {
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
    private struct PlayButton<ButtonStyle: BookmarksStyle>: View {
        let title: String
        @ObservedObject var style: ButtonStyle

        var body: some View {
            HStack(spacing: 6) {
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .fixedSize()

                Image(systemName: "play.fill")
                    .font(.system(size: 10))
            }
            .foregroundStyle(style.playButtonText)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(style.playButtonBackground)
            .cornerRadius(.infinity)
            .overlay(
                style.playButtonStroke.map {
                    RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                        .inset(by: 1)
                        .stroke($0, lineWidth: 1.5)
                }
            )
        }
    }
}
