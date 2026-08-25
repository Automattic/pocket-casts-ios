import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

/// A single bookmark in full: the episode it was taken from, and the transcript passage
/// it captured, shown in place within the episode's full transcript.
struct BookmarkDetailsView: View {
    @ObservedObject var viewModel: BookmarkDetailsViewModel

    @EnvironmentObject private var theme: Theme

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 56

    var body: some View {
        layout
            // Top-anchored: the header sits at the top whatever height the transcript takes
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.primaryUi01.ignoresSafeArea())
            .miniPlayerSafeAreaInset()
            .task {
                await viewModel.loadTranscript()
            }
    }

    /// With a passage, the transcript takes the rest of the screen and scrolls by itself
    /// under the fixed header; without one there's only the header, scrolling as a whole
    @ViewBuilder
    private var layout: some View {
        if viewModel.passage != nil {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    header
                    details
                }
                .padding(.horizontal, 16)

                transcriptSection
            }
            .padding(.top, 16)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    details
                }
                .padding(16)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                podcastTitle

                viewModel.episode.map {
                    Text($0.displayableTitle())
                        .font(size: 15, style: .subheadline, weight: .semibold)
                        .kerning(-0.4)
                        .foregroundStyle(theme.primaryText01)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            playButton
        }
    }

    @ViewBuilder
    private var podcastTitle: some View {
        if let title = viewModel.podcastTitle {
            podcastTitleText(title)
        } else if viewModel.isLoadingPodcastTitle {
            podcastTitleText(Self.podcastTitlePlaceholder)
                .redacted(reason: .placeholder)
                .accessibilityHidden(true)
        }
    }

    private func podcastTitleText(_ title: String) -> some View {
        Text(title)
            .font(size: 11, style: .caption2, weight: .semibold)
            .kerning(-0.4)
            .foregroundStyle(theme.primaryText02)
            .lineLimit(1)
    }

    /// Stands in for the podcast title while it loads. The redaction blocks it out,
    /// so it's never read, it only gives the placeholder the shape of a title.
    private static let podcastTitlePlaceholder = "The Podcast Title"

    @ViewBuilder
    private var artwork: some View {
        if let episode = viewModel.episode {
            if let onEpisodeTapped = viewModel.onEpisodeTapped {
                Button(action: onEpisodeTapped) {
                    artworkImage(for: episode)
                }
                .buttonStyle(.plain)
            } else {
                artworkImage(for: episode)
            }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(theme.primaryUi05)
                .frame(width: imageSize, height: imageSize)
        }
    }

    private func artworkImage(for episode: BaseEpisode) -> some View {
        EpisodeImage(episode: episode)
            .aspectRatio(contentMode: .fill)
            .frame(width: imageSize, height: imageSize)
            .cornerRadius(8)
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

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(created)
                .font(style: .footnote, weight: .medium)
                .foregroundStyle(theme.primaryText02)

            Text(viewModel.bookmark.title)
                .font(size: 22, style: .title3, weight: .bold)
                .foregroundStyle(theme.primaryText01)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Transcript

    @ViewBuilder
    private var transcriptSection: some View {
        Group {
            if let snippet = viewModel.transcriptSnippet {
                transcriptView(for: snippet)
            } else if viewModel.isLoadingTranscript {
                loadingPlaceholder
            } else if let passage = viewModel.passage {
                // No transcript to place the passage in, so it stands alone
                ScrollView {
                    passageView(passage)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoadingTranscript)
    }

    private func transcriptView(for snippet: BookmarkTranscriptSnippet) -> some View {
        BookmarkTranscriptReadView(transcript: snippet.transcript,
                                   passageRange: snippet.range,
                                   bookmarkCharacterIndex: bookmarkCharacterIndex(for: snippet),
                                   topInset: TranscriptFade.top,
                                   bottomInset: TranscriptFade.bottom,
                                   passageColor: UIColor(theme.primaryText01),
                                   surroundingColor: UIColor(theme.primaryText02),
                                   selectionColor: UIColor(theme.primaryInteractive01))
            .mask(edgeFade)
            // Re-created when an edit moves the passage, so the view scrolls to it anew
            .id(snippet.range)
    }

    /// The line the bookmark's glyph marks: where the bookmark sits on the reference
    /// timeline when that's resolved, or the start of the passage otherwise
    private func bookmarkCharacterIndex(for snippet: BookmarkTranscriptSnippet) -> Int {
        viewModel.bookmark.referenceTime.flatMap { snippet.transcript.characterIndex(at: $0) } ?? snippet.range.location
    }

    /// Softens both edges so lines fade out as they scroll past, rather than being clipped
    private var edgeFade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: TranscriptFade.top)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: TranscriptFade.bottom)
        }
    }

    /// The passage with placeholder text standing in for the transcript around it while
    /// the real one loads
    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 20) {
            placeholderParagraph(Self.leadingPlaceholder)

            // The glyph waits for the real transcript, where it can mark the right line
            viewModel.passage.map { passageView($0, showsBookmarkIndicator: false) }

            placeholderParagraph(Self.trailingPlaceholder)
        }
        // Starts clear of the fade, where the transcript that replaces it starts too
        .padding(.top, TranscriptFade.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    private func placeholderParagraph(_ text: String) -> some View {
        Text(text)
            .font(size: BookmarkTranscriptStyle.fontSize, style: .body, design: .serif)
            .lineSpacing(BookmarkTranscriptStyle.lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(theme.primaryText02)
            .redacted(reason: .placeholder)
            .padding(.horizontal, BookmarkTranscriptTextView.gutterWidth)
            .accessibilityHidden(true)
    }

    /// The passage on its own, in the same text view the full transcript uses, so it
    /// reads identically before and after the transcript arrives
    private func passageView(_ passage: String, showsBookmarkIndicator: Bool = true) -> some View {
        BookmarkPassageTextView(passage: passage,
                                showsBookmarkIndicator: showsBookmarkIndicator,
                                textColor: UIColor(theme.primaryText01),
                                selectionColor: UIColor(theme.primaryInteractive01))
    }

    /// Stand-ins for the transcript around the passage while it loads. The redaction
    /// blocks them out, so they're never read; they only give the placeholders the
    /// shape of prose.
    private static let leadingPlaceholder = """
    The lines of the transcript leading into the bookmarked passage land here once the \
    episode transcript has been fetched, filling out a few lines above it.
    """

    private static let trailingPlaceholder = """
    The rest of the transcript follows the passage the moment it arrives, running on \
    long enough to fill the space below with the shape of the conversation as it \
    continues past the bookmarked moment, line after line, until the fetched text \
    takes its place.
    """

    private var timestamp: String {
        TimeFormatter.shared.playTimeFormat(time: viewModel.bookmark.time)
    }

    private var created: String {
        DateFormatter.localizedString(from: viewModel.bookmark.created, dateStyle: .medium, timeStyle: .short)
    }
}

// MARK: - TranscriptFade

/// How deep the transcript fades out at each edge. The transcript keeps the same room
/// clear at its own edges, so its first and last lines come to rest clear of the fade.
private enum TranscriptFade {
    static let top: CGFloat = 96
    static let bottom: CGFloat = 64
}

// MARK: - BookmarkPassageTextView

/// The passage alone — while the transcript loads, or when there is none — rendered by
/// the same text view the full transcript uses: the same styling and gutter, optionally
/// the glyph marking its first line, and the text already selectable. Sized to its
/// content, so it sits in the surrounding layout rather than scrolling.
private struct BookmarkPassageTextView: UIViewRepresentable {
    let passage: String
    let showsBookmarkIndicator: Bool
    let textColor: UIColor
    let selectionColor: UIColor

    func makeUIView(context: Context) -> BookmarkTranscriptTextView {
        // TextKit 1: the indicator's line lookup works off `layoutManager`
        let textView = BookmarkTranscriptTextView(usingTextLayoutManager: false)
        textView.attributedText = styledText()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 0,
                                                   left: BookmarkTranscriptTextView.gutterWidth,
                                                   bottom: 0,
                                                   right: BookmarkTranscriptTextView.gutterWidth)
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = selectionColor
        if showsBookmarkIndicator {
            textView.showBookmarkIndicator(at: 0, color: textColor)
        }
        return textView
    }

    func updateUIView(_ textView: BookmarkTranscriptTextView, context: Context) {
        let styled = styledText()
        if !textView.attributedText.isEqual(styled) {
            textView.attributedText = styled
        }

        textView.tintColor = selectionColor
        textView.setBookmarkIndicatorColor(textColor)
    }

    /// Asks the text view how tall the passage runs at the width it's offered
    func sizeThatFits(_ proposal: ProposedViewSize, uiView textView: BookmarkTranscriptTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }

        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    private func styledText() -> NSAttributedString {
        BookmarkTranscriptStyle.styledTranscript(NSAttributedString(string: passage), textColor: textColor)
    }
}

// MARK: - BookmarkTranscriptReadView

/// The full transcript as selectable read-only text, scrolled so the bookmarked passage
/// starts in view. The passage reads in the primary color with the transcript around it
/// receding into the secondary one, and a glyph in the leading gutter marks the line
/// the bookmark sits on.
private struct BookmarkTranscriptReadView: UIViewRepresentable {
    let transcript: TranscriptModel
    let passageRange: NSRange
    let bookmarkCharacterIndex: Int

    /// The room the transcript keeps clear at each edge, matching the fade drawn over it
    let topInset: CGFloat
    let bottomInset: CGFloat

    let passageColor: UIColor
    let surroundingColor: UIColor
    let selectionColor: UIColor

    /// Where the passage sits vertically once scrolled to
    private let verticalAnchor: CGFloat = 0.4

    func makeUIView(context: Context) -> BookmarkTranscriptTextView {
        // TextKit 1: `scrollToRange` and the indicator's line lookup work off `layoutManager`
        let textView = BookmarkTranscriptTextView(usingTextLayoutManager: false)
        textView.attributedText = styledText()
        textView.isEditable = false
        // Selectable so a quote can be copied out of the transcript
        textView.isSelectable = true
        textView.backgroundColor = .clear
        // The gutter on both sides is the text view's own inset rather than outside
        // padding, so the bookmark indicator can sit in the leading one, beside the text
        textView.textContainerInset = UIEdgeInsets(top: topInset,
                                                   left: BookmarkTranscriptTextView.gutterWidth,
                                                   bottom: bottomInset,
                                                   right: BookmarkTranscriptTextView.gutterWidth)
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = selectionColor
        textView.contentInsetAdjustmentBehavior = .always
        textView.showBookmarkIndicator(at: bookmarkCharacterIndex, color: passageColor)

        // The passage can only be scrolled to once the text has a width to be laid out in
        textView.alpha = 0
        textView.onFirstLayout = { [weak textView] in
            guard let textView else { return }

            UIView.performWithoutAnimation {
                textView.scrollToRange(passageRange, verticalAnchor: verticalAnchor, animated: false)
                textView.alpha = 1
            }
        }

        context.coordinator.colors = [passageColor, surroundingColor]
        return textView
    }

    func updateUIView(_ textView: BookmarkTranscriptTextView, context: Context) {
        guard context.coordinator.colors != [passageColor, surroundingColor] else { return }

        // Recolored in place: only the colors changed, and the text keeps its layout
        context.coordinator.colors = [passageColor, surroundingColor]
        applyColors(to: textView.textStorage)
        textView.setBookmarkIndicatorColor(passageColor)
        textView.tintColor = selectionColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var colors: [UIColor]?
    }

    private func styledText() -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: BookmarkTranscriptStyle.styledTranscript(transcript.attributedText,
                                                                                                        textColor: surroundingColor))
        applyPassageColor(to: text)
        return text
    }

    private func applyColors(to text: NSMutableAttributedString) {
        text.addAttribute(.foregroundColor, value: surroundingColor, range: NSRange(location: 0, length: text.length))
        applyPassageColor(to: text)
    }

    private func applyPassageColor(to text: NSMutableAttributedString) {
        let clamped = NSIntersectionRange(passageRange, NSRange(location: 0, length: text.length))
        guard clamped.length > 0 else { return }

        text.addAttribute(.foregroundColor, value: passageColor, range: clamped)
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
                                                 transcriptSnippet: previewSnippet,
                                                 bookmarkManager: .init()))
        }
        .setupDefaultEnvironment()
        .previewDisplayName("Transcript loaded")

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
        .previewDisplayName("Loading")
    }

    private static var previewEpisode: Episode {
        let episode = Episode()
        episode.title = "Higher Educations Identify Crisis"
        return episode
    }

    private static let previewPassage = """
    It sounds radical, but it's arguably more honest than pretending there's a meaningful \
    distinction between applicant 1,800 and applicant 2,100.
    """

    private static var previewSnippet: BookmarkTranscriptSnippet? {
        let transcript = previewTranscript
        guard let range = BookmarkTranscriptSnippetExtractor.passageRange(for: previewPassage, at: nil, in: transcript.attributedText) else {
            return nil
        }

        return BookmarkTranscriptSnippet(transcript: transcript, range: range)
    }

    private static var previewTranscript: TranscriptModel {
        TranscriptModel.makeModel(from: """
        WEBVTT

        00:22:40.000 --> 00:22:50.000
        that's the thing about selective admissions — the difference between the kid who gets in and the kid who doesn't is often basically noise.

        00:22:50.000 --> 00:23:00.000
        Right, and that's why some researchers have floated the lottery idea. You set a bar for who's qualified, and past that, you just draw names.

        00:23:00.000 --> 00:23:10.000
        It sounds radical, but it's arguably more honest than pretending there's a meaningful distinction between applicant 1,800 and applicant 2,100.

        00:23:10.000 --> 00:23:25.000
        And meanwhile the debt side of this is its own crisis. Families are taking on six figures for a credential that for most of the last century, was basically a guaranteed ticket to the middle class. And that promise is getting shakier.
        """, format: .vtt) ?? TranscriptModel(attributedText: NSAttributedString(string: ""), cues: [], type: "", hasJavascript: false)
    }
}
