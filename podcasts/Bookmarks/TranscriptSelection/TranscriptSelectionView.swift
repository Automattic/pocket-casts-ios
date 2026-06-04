import Combine
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

struct TranscriptSelectionView: View {
    @ObservedObject var viewModel: TranscriptSelectionViewModel
    @ObservedObject var theme: TranscriptSelectionTheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            mainView

            Image("close")
                .renderingMode(.template)
                .foregroundStyle(theme.closeButton)
                .buttonize {
                    viewModel.cancel()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(theme.background)
        .onAppear {
            viewModel.generateTitle()
        }
    }

    // MARK: - Views

    private var mainView: some View {
        VStack(spacing: 16) {
            headerView
            cueListView
            selectionInfo
            titleField
            saveButton
        }
        .padding(.top, 18)
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text(L10n.smartBookmarkTitle)
                .foregroundStyle(theme.title)
                .font(size: 19, style: .title3, weight: .bold)

            Text(L10n.smartBookmarkSubtitle)
                .foregroundStyle(theme.subtitle)
                .font(style: .callout)
        }
    }

    private var cueListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(0..<viewModel.cues.count, id: \.self) { index in
                        cueRow(at: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                proxy.scrollTo(viewModel.bookmarkCueIndex, anchor: .center)
            }
            .onChange(of: viewModel.startCueIndex) { _ in
                withAnimation {
                    proxy.scrollTo(viewModel.startCueIndex, anchor: .center)
                }
            }
        }
    }

    private func cueRow(at index: Int) -> some View {
        let isSelected = index >= viewModel.startCueIndex && index <= viewModel.endCueIndex
        let isBookmarkCue = index == viewModel.bookmarkCueIndex
        let cue = viewModel.cues[index]
        let nsString = viewModel.fullText as NSString
        let text = nsString.substring(with: cue.characterRange).trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(spacing: 0) {
            if isBookmarkCue {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.accent)
                    .frame(width: 20)
            } else {
                Spacer().frame(width: 20)
            }

            Text(text)
                .font(style: .body)
                .foregroundStyle(isSelected ? theme.selectedText : theme.dimmedText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.selectedBackground : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectCue(at: index)
            }
        }
    }

    private var selectionInfo: some View {
        HStack(spacing: 6) {
            Text(L10n.smartBookmarkLineCount(viewModel.selectedCueCount))
                .foregroundStyle(theme.subtitle)
                .font(style: .caption)

            Text("·")
                .foregroundStyle(theme.subtitle)
                .font(style: .caption)

            Text(viewModel.formattedTimeRange)
                .foregroundStyle(theme.subtitle)
                .font(style: .caption)
        }
    }

    @ViewBuilder
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.smartBookmarkTitleLabel)
                .foregroundStyle(theme.subtitle)
                .font(style: .caption)

            if viewModel.isGeneratingTitle {
                HStack {
                    ProgressView()
                        .tint(theme.subtitle)
                    Text(L10n.smartBookmarkGeneratingTitle)
                        .foregroundStyle(theme.subtitle)
                        .font(style: .callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                TextField(L10n.bookmarkDefaultTitle, text: $viewModel.bookmarkTitle)
                    .foregroundStyle(theme.title)
                    .font(size: 20, style: .title3, weight: .semibold)
                    .textFieldStyle(.plain)
                    .accentColor(theme.accent)
                    .onChange(of: viewModel.bookmarkTitle) { newValue in
                        let max = Constants.Values.bookmarkMaxTitleLength
                        if newValue.count > max {
                            viewModel.bookmarkTitle = String(newValue.prefix(max))
                        }
                    }
            }

            Divider().background(theme.divider)
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        Button(L10n.saveBookmark) {
            viewModel.save()
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.saveButtonText, backgroundColor: theme.accent))
        .disabled(viewModel.isGeneratingTitle)
    }
}

// MARK: - Theme

class TranscriptSelectionTheme: ThemeObserver {
    let episode: BaseEpisode?

    init(episode: BaseEpisode?) {
        self.episode = episode
    }

    var background: Color {
        PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme, episode: episode).color
    }

    var title: Color { theme.playerContrast01 }
    var subtitle: Color { theme.playerContrast02 }
    var closeButton: Color { theme.playerContrast01 }
    var dimmedText: Color { theme.playerContrast05 }

    var selectedText: Color { theme.playerContrast01 }
    var selectedBackground: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color.opacity(0.25)
    }

    var accent: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color
    }

    var divider: Color { theme.playerContrast05 }

    var saveButtonText: Color {
        accent.luminance() < 0.5 ? .white : .black
    }
}
