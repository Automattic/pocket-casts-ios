import PocketCastsUtils
import SwiftUI

/// The full episode transcript with the bookmark's passage selected, so the user can
/// pick a different one.
struct BookmarkTranscriptEditView: View {
    let transcript: TranscriptModel

    /// The bookmark's position on the transcript's reference timeline, marking the line it
    /// sits on; nil for a bookmark that was never resolved against the reference timeline.
    let referenceTime: TimeInterval?

    @Binding var selection: NSRange

    @ObservedObject var theme: BookmarkEditTheme

    var body: some View {
        VStack(spacing: 0) {
            subtitle
                .padding(.horizontal, 16)

            // The room the transcript keeps clear at the top is the gap below the subtitle
            TranscriptSelectionTextView(transcript: transcript,
                                        bookmarkCharacterIndex: referenceTime.flatMap { transcript.characterIndex(at: $0) },
                                        selection: $selection,
                                        topInset: Self.topFadeDepth,
                                        textColor: UIColor(theme.title),
                                        selectionColor: UIColor(theme.transcriptSelection))
                .mask(topFadeMask)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
        .background(theme.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
        // Colors the back button the bar gives us for free
        .tint(theme.title)
        .navigationTitle(L10n.bookmarkEditTranscriptTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The bar's own title knows nothing about the player's colors
            ToolbarItem(placement: .principal) {
                Text(L10n.bookmarkEditTranscriptTitle)
                    .font(style: .headline, weight: .semibold)
                    .foregroundStyle(theme.title)
            }
        }
    }

    // MARK: - Views

    private var subtitle: some View {
        Text(L10n.bookmarkEditTranscriptSubtitle)
            .foregroundStyle(theme.subTitle)
            .font(style: .callout)
            .multilineTextAlignment(.center)
    }

    /// Softens the top edge so lines dissolve as they scroll past, rather than being clipped
    private var topFadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: Self.topFadeDepth)
            Color.black
        }
    }

    /// How deep the transcript fades out at the top. It keeps the same room clear at its
    /// own top edge, so its first line comes to rest clear of the fade.
    private static let topFadeDepth: CGFloat = 48
}

// MARK: - TranscriptSelectionTextView

/// The transcript as selectable text, scrolled to the bookmark's passage. A tap selects
/// the sentence it lands in, rather than collapsing the selection to a caret and leaving
/// the bookmark with no passage at all.
private struct TranscriptSelectionTextView: UIViewRepresentable {
    let transcript: TranscriptModel

    /// The character whose line the bookmark indicator is drawn beside; nil shows no indicator
    let bookmarkCharacterIndex: Int?

    @Binding var selection: NSRange

    /// The room the transcript keeps clear at the top, matching the fade drawn over it
    let topInset: CGFloat

    let textColor: UIColor
    let selectionColor: UIColor

    /// Where the passage sits vertically once scrolled to
    private let verticalAnchor: CGFloat = 0.5

    func makeUIView(context: Context) -> BookmarkTranscriptTextView {
        // TextKit 1: `scrollToRange` and the character index lookups work off `layoutManager`
        let textView = BookmarkTranscriptTextView(usingTextLayoutManager: false)
        textView.attributedText = BookmarkTranscriptStyle.styledTranscript(transcript.attributedText, textColor: textColor)
        textView.isEditable = false
        textView.backgroundColor = .clear
        // The gutter on both sides is the text view's own inset rather than outside
        // padding, so the bookmark indicator can sit in the leading one, beside the text
        textView.textContainerInset = UIEdgeInsets(top: topInset,
                                                   left: BookmarkTranscriptTextView.gutterWidth,
                                                   bottom: 0,
                                                   right: BookmarkTranscriptTextView.gutterWidth)
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = selectionColor
        // Leaves room to scroll the text clear of the home indicator it runs under
        textView.contentInsetAdjustmentBehavior = .always

        if let bookmarkCharacterIndex {
            textView.showBookmarkIndicator(at: bookmarkCharacterIndex, color: textColor)
        }

        // The passage can only be scrolled to once the text has a width to be laid out in
        textView.alpha = 0
        textView.onFirstLayout = { [weak textView] in
            guard let textView else { return }

            UIView.performWithoutAnimation {
                // A selection is only drawn while the text view is the first responder
                textView.becomeFirstResponder()
                textView.selectedRange = selection
                textView.scrollToRange(selection, verticalAnchor: verticalAnchor, animated: false)
                textView.alpha = 1
            }

            // Listen only from here on: the passage above would report itself back as a
            // change, and the empty selection it starts out with would overwrite it
            textView.delegate = context.coordinator
        }

        return textView
    }

    func updateUIView(_ textView: BookmarkTranscriptTextView, context: Context) {
        guard textView.selectedRange != selection else { return }

        textView.selectedRange = selection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var selection: NSRange

        init(selection: Binding<NSRange>) {
            _selection = selection
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Only the user's own selection counts: the responder machinery also moves the
            // selection on its own — resigning during a pop, say — and a passage rewritten
            // by those events would look like one the user picked
            guard textView.isFirstResponder, textView.window != nil else { return }

            let range = textView.selectedRange

            if range.length == 0 {
                let sentence = BookmarkTranscriptSnippetExtractor.sentenceRange(containing: range.location,
                                                                               in: textView.text)
                if sentence != range {
                    // Re-enters this method with the expanded selection
                    textView.selectedRange = sentence
                    return
                }
            }

            selection = range
        }

        /// The copy and share actions a selection normally offers are just in the way here
        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            nil
        }
    }
}

// MARK: - Theme

private extension BookmarkEditTheme {
    var transcriptSelection: Color { textFieldAccent }
}

// MARK: - Preview

struct BookmarkTranscriptEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookmarkTranscriptEditView(transcript: previewTranscript,
                                       referenceTime: 8,
                                       selection: .constant(NSRange(location: 0, length: 42)),
                                       theme: .init(episode: nil))
        }
        .setupDefaultEnvironment()
    }

    private static var previewTranscript: TranscriptModel {
        TranscriptModel.makeModel(from: """
        WEBVTT

        00:00:00.000 --> 00:00:05.000
        that's the thing about selective admissions — the difference between the kid who gets in

        00:00:05.000 --> 00:00:10.000
        and the kid who doesn't is often basically noise. Right, and that's why some researchers

        00:00:10.000 --> 00:00:15.000
        have floated the lottery idea. You set a bar for who's qualified, and past that, you just draw names.
        """, format: .vtt) ?? TranscriptModel(attributedText: NSAttributedString(string: ""), cues: [], type: "", hasJavascript: false)
    }
}
