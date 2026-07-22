import PocketCastsUtils
import SwiftUI

/// The full episode transcript with the bookmark's passage selected, so the user can
/// pick a different one.
struct BookmarkTranscriptEditView: View {
    let transcript: TranscriptModel

    @Binding var selection: NSRange

    @ObservedObject var theme: BookmarkEditTheme

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            subtitle

            TranscriptSelectionTextView(transcript: transcript,
                                        selection: $selection,
                                        textColor: UIColor(theme.title),
                                        selectionColor: UIColor(theme.transcriptSelection))
        }
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .top])
        .background(theme.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(L10n.bookmarkEditTranscriptTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }

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

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image("nav-back")
                .renderingMode(.template)
                .foregroundStyle(theme.title)
        }
        .accessibilityLabel(L10n.back)
    }
}

// MARK: - TranscriptSelectionTextView

/// The transcript as selectable text, scrolled to the bookmark's passage. A tap selects
/// the sentence it lands in, rather than collapsing the selection to a caret and leaving
/// the bookmark with no passage at all.
private struct TranscriptSelectionTextView: UIViewRepresentable {
    let transcript: TranscriptModel

    @Binding var selection: NSRange

    let textColor: UIColor
    let selectionColor: UIColor

    /// Where the passage sits vertically once scrolled to
    private let verticalAnchor: CGFloat = 0.3

    func makeUIView(context: Context) -> SelectableTextView {
        // TextKit 1: `scrollToRange` and the character index lookups work off `layoutManager`
        let textView = SelectableTextView(usingTextLayoutManager: false)
        textView.attributedText = styledText()
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = selectionColor
        textView.showsVerticalScrollIndicator = false
        // Leaves room to scroll the text clear of the home indicator it runs under
        textView.contentInsetAdjustmentBehavior = .always

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

    func updateUIView(_ textView: SelectableTextView, context: Context) {
        guard textView.selectedRange != selection else { return }

        textView.selectedRange = selection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    private func styledText() -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: transcript.attributedText)
        let fullRange = NSRange(location: 0, length: text.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = BookmarkTranscriptStyle.lineHeight
        paragraphStyle.maximumLineHeight = BookmarkTranscriptStyle.lineHeight
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .natural

        text.addAttributes([.paragraphStyle: paragraphStyle,
                            .font: BookmarkTranscriptStyle.font,
                            .baselineOffset: BookmarkTranscriptStyle.baselineOffset,
                            .foregroundColor: textColor],
                           range: fullRange)

        text.enumerateAttribute(.transcriptSpeaker, in: fullRange, options: [.longestEffectiveRangeNotRequired]) { value, range, _ in
            guard value != nil else { return }

            text.addAttribute(.font, value: BookmarkTranscriptStyle.speakerFont, range: range)
        }

        return text
    }

    /// A text view that reports the first layout pass it can scroll and select in
    class SelectableTextView: UITextView {
        var onFirstLayout: (() -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()

            guard window != nil, bounds.width > 0, let onFirstLayout else { return }

            // Cleared first: the callback lays the text out again as it scrolls
            self.onFirstLayout = nil
            onFirstLayout()
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var selection: NSRange

        init(selection: Binding<NSRange>) {
            _selection = selection
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
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
