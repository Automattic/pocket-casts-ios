import Combine
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

struct TranscriptSelectionView: View {
    @ObservedObject var viewModel: TranscriptSelectionViewModel
    @ObservedObject var theme: TranscriptSelectionTheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(L10n.smartBookmarkSubtitle)
                    .foregroundStyle(theme.subtitle)
                    .font(style: .subheadline)
                    .padding(.top, 4)
                cueListView
                selectionInfo
                titleField
            }
            .padding(.horizontal)
            .padding(.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle(viewModel.isEditing ? L10n.smartBookmarkEditTitle : L10n.smartBookmarkTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.closeButton)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    confirmButton
                }
            }
        }
        .onAppear {
            viewModel.generateTitle()
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        if #available(iOS 26.0, *) {
            Button(role: .confirm) {
                viewModel.save()
            }
            .tint(theme.accent)
        } else {
            Button {
                viewModel.save()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(theme.saveButtonText, theme.accent)
            }
            .buttonStyle(.plain)
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
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                proxy.scrollTo(viewModel.startCueIndex, anchor: .top)
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
        let cue = viewModel.cues[index]
        let nsString = viewModel.fullText as NSString
        let text = nsString.substring(with: cue.characterRange).trimmingCharacters(in: .whitespacesAndNewlines)

        return Text(text)
            .font(.system(.body, design: .serif))
            .lineSpacing(3)
            .foregroundStyle(isSelected ? theme.selectedText : theme.dimmedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.smartBookmarkTitleLabel)
                .foregroundStyle(theme.subtitle)
                .font(style: .caption, weight: .semibold)

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
                .overlay(alignment: .bottom) {
                    theme.divider.frame(height: 1)
                }
            } else {
                TextField(L10n.bookmarkDefaultTitle, text: $viewModel.bookmarkTitle)
                    .foregroundStyle(theme.title)
                    .font(size: 22, style: .title2, weight: .bold)
                    .textFieldStyle(.plain)
                    .accentColor(theme.accent)
                    .onChange(of: viewModel.bookmarkTitle) { newValue in
                        let max = Constants.Values.bookmarkMaxTitleLength
                        if newValue.count > max {
                            viewModel.bookmarkTitle = String(newValue.prefix(max))
                        }
                    }
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        theme.divider.frame(height: 1)
                    }
            }
        }
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
    var dimmedText: Color { theme.playerContrast02 }

    var selectedText: Color { theme.playerContrast01 }
    var selectedBackground: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color.opacity(0.25)
    }

    var accent: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color
    }

    var divider: Color { theme.playerContrast05 }
    var titleFieldBackground: Color { theme.playerContrast01.opacity(0.08) }

    var saveButtonText: Color {
        accent.luminance() < 0.5 ? .white : .black
    }
}

class TranscriptSelectionAppTheme: TranscriptSelectionTheme {
    override var background: Color { AppTheme.color(for: .primaryUi01, theme: theme) }
    override var title: Color { AppTheme.color(for: .primaryText01, theme: theme) }
    override var subtitle: Color { AppTheme.color(for: .primaryText02, theme: theme) }
    override var closeButton: Color { AppTheme.color(for: .primaryText01, theme: theme) }
    override var dimmedText: Color { AppTheme.color(for: .primaryText02, theme: theme) }
    override var selectedText: Color { AppTheme.color(for: .primaryText01, theme: theme) }
    override var selectedBackground: Color { AppTheme.color(for: .primaryInteractive01, theme: theme).opacity(0.15) }
    override var accent: Color { AppTheme.color(for: .primaryInteractive01, theme: theme) }
    override var divider: Color { AppTheme.color(for: .primaryUi05, theme: theme) }
    override var titleFieldBackground: Color { AppTheme.color(for: .primaryUi02, theme: theme) }
    override var saveButtonText: Color { AppTheme.color(for: .primaryInteractive02, theme: theme) }
}
