import PocketCastsUtils
import SwiftUI

/// The full episode transcript with the bookmark's passage selected, so the user can
/// pick a different one.
struct BookmarkTranscriptEditView: View {
    let transcript: TranscriptModel

    @Binding var selection: NSRange

    /// The playback moment the bookmark marks, so a marker can sit beside the line it lands on
    let bookmarkTime: TimeInterval

    @ObservedObject var theme: BookmarkEditTheme

    /// Where the marker's line currently sits vertically within the text view, or nil while
    /// that line is scrolled out of view
    @State private var markerY: CGFloat?

    private let markerGutterWidth: CGFloat = 24
    private let markerSpacing: CGFloat = 8
    private let markerIconSize: CGFloat = 18

    var body: some View {
        VStack(spacing: 18) {
            subtitle

            passagePicker
        }
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .top])
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

    /// The transcript with a bookmark marker in the leading gutter, when the moment can be
    /// placed against a line
    private var passagePicker: some View {
        HStack(alignment: .top, spacing: markerSpacing) {
            if anchorLocation != nil {
                markerGutter
            }

            TranscriptSelectionTextView(transcript: transcript,
                                        selection: $selection,
                                        anchorLocation: anchorLocation,
                                        markerY: $markerY,
                                        textColor: UIColor(theme.title),
                                        selectionColor: UIColor(theme.transcriptSelection))
        }
    }

    private var markerGutter: some View {
        Color.clear
            .frame(width: markerGutterWidth)
            .overlay {
                if let markerY {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: markerIconSize))
                        .foregroundStyle(theme.title)
                        .position(x: markerGutterWidth / 2, y: markerY)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityHidden(true)
    }

    // MARK: - Marker position

    /// The character in the transcript nearest the bookmarked moment. Nil when the transcript
    /// carries no cue timing to place it against.
    private var anchorLocation: Int? {
        guard !transcript.cues.isEmpty else { return nil }

        let cue = transcript.firstCue(containing: bookmarkTime)
            ?? transcript.cues.last { $0.startTime <= bookmarkTime }
            ?? transcript.cues.first
        guard let cue else { return nil }

        // Interpolate within the cue so the marker tracks the moment, not just the cue's start
        let span = max(cue.endTime - cue.startTime, .leastNonzeroMagnitude)
        let fraction = min(max((bookmarkTime - cue.startTime) / span, 0), 1)
        let offset = Int((Double(cue.characterRange.length) * fraction).rounded())
        return cue.characterRange.location + offset
    }
}

// MARK: - TranscriptSelectionTextView

/// The transcript as selectable text, scrolled to the bookmark's passage. A tap selects
/// the sentence it lands in, rather than collapsing the selection to a caret and leaving
/// the bookmark with no passage at all.
private struct TranscriptSelectionTextView: UIViewRepresentable {
    let transcript: TranscriptModel

    @Binding var selection: NSRange

    /// The character the bookmark marker points at, if the moment could be placed
    let anchorLocation: Int?

    /// Reports where that character sits vertically as the text scrolls, or nil when it's
    /// scrolled out of view
    @Binding var markerY: CGFloat?

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

            // Placed off the layout pass so the marker's state settles outside SwiftUI's update
            DispatchQueue.main.async {
                context.coordinator.updateMarker(in: textView)
            }
        }

        return textView
    }

    func updateUIView(_ textView: SelectableTextView, context: Context) {
        guard textView.selectedRange != selection else { return }

        textView.selectedRange = selection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, markerY: $markerY, anchorLocation: anchorLocation)
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
        @Binding private var markerY: CGFloat?
        private let anchorLocation: Int?

        init(selection: Binding<NSRange>, markerY: Binding<CGFloat?>, anchorLocation: Int?) {
            _selection = selection
            _markerY = markerY
            self.anchorLocation = anchorLocation
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let textView = scrollView as? UITextView else { return }

            updateMarker(in: textView)
        }

        /// Positions the marker beside the line holding the bookmarked moment, hiding it while
        /// that line is scrolled out of view.
        func updateMarker(in textView: UITextView) {
            guard let anchorLocation else {
                setMarkerY(nil)
                return
            }

            let length = (textView.text as NSString).length
            guard length > 0 else {
                setMarkerY(nil)
                return
            }

            let location = min(max(anchorLocation, 0), length - 1)
            let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: NSRange(location: location, length: 1), actualCharacterRange: nil)
            var rect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
            rect.origin.y += textView.textContainerInset.top

            // Content coordinate to a position within the visible bounds
            let y = rect.midY - textView.contentOffset.y
            setMarkerY((0...textView.bounds.height).contains(y) ? y : nil)
        }

        /// Only writes back a meaningful move, so scrolling doesn't churn SwiftUI every frame
        private func setMarkerY(_ y: CGFloat?) {
            switch (markerY, y) {
            case (nil, nil):
                return
            case let (current?, value?) where abs(current - value) < 0.5:
                return
            default:
                markerY = y
            }
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
                                       bookmarkTime: 8,
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
