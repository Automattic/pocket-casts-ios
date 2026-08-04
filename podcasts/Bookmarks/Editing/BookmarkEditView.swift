import PocketCastsDataModel
import SwiftUI

/// The add/edit bookmark sheet, with a generated title suggestion when one is available.
struct BookmarkEditView: View {
    @ObservedObject var viewModel: BookmarkEditViewModel
    @ObservedObject var theme: BookmarkEditTheme

    @State private var isTitleFocused = false

    /// The title is only focused the first time the form appears, so coming back from
    /// the transcript editor doesn't pop the keyboard and select the title again
    @State private var hasFocusedTitle = false

    @State private var isEditingTranscript = false

    @State private var titleTextView: BookmarkTitleTextView.TextView?

    var body: some View {
        NavigationStack {
            form
                .navigationDestination(isPresented: $isEditingTranscript) {
                    transcriptEditor
                }
                .onChange(of: isEditingTranscript) { _, isEditing in
                    isEditing ? viewModel.passageEditorShown() : viewModel.passageEditorDismissed()
                }
        }
    }

    // MARK: - Views

    /// The fields scroll so they stay reachable at large text sizes, while the save
    /// button stays pinned to the bottom, above the keyboard
    private var form: some View {
        ScrollView {
            VStack(spacing: 32) {
                titleSection
                transcriptSection
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.easeInOut(duration: 0.2), value: viewModel.passage)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCapturingTranscript)
        .safeAreaInset(edge: .bottom) {
            saveButton
                .padding()
                .background(theme.background)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(viewModel.headerTitle)
        .navigationBarTitleDisplayMode(.inline)

        // Keep the themed background under the bar, so scrolled content doesn't
        // surface the system material behind the title
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                closeButton
            }

            // The bar's own title knows nothing about the player's colors
            ToolbarItem(placement: .principal) {
                Text(viewModel.headerTitle)
                    .font(style: .headline, weight: .semibold)
                    .foregroundStyle(theme.title)
            }
        }
        .onAppear {
            guard !hasFocusedTitle else { return }

            hasFocusedTitle = true
            isTitleFocused = true
        }
    }

    @ViewBuilder
    private var transcriptEditor: some View {
        if let transcript = viewModel.snippet?.transcript {
            BookmarkTranscriptEditView(transcript: transcript,
                                       referenceTime: viewModel.referenceTime,
                                       selection: $viewModel.transcriptRange,
                                       theme: theme)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            section {
                Text(L10n.bookmarkTitleLabel)
            } content: {
                titleField
            }

            if case .available(let suggestion) = viewModel.titleSuggestion {
                suggestionButton(suggestion)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.titleSuggestion)
    }

    /// A section of the form, with its header styled as a label
    private func section<Header: View>(@ViewBuilder header: () -> Header,
                                       @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header()
                .font(style: .footnote)
                .foregroundStyle(theme.subTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleField: some View {
        BookmarkTitleTextView(
            text: $viewModel.title,
            isFocused: $isTitleFocused,
            textColor: UIColor(theme.textField),
            accentColor: UIColor(theme.textFieldAccent),
            onBeginEditing: { textView in
                titleTextView = textView
                selectAll(in: textView)
            },
            onSubmit: {
                viewModel.save()
            }
        )
        .overlay(alignment: .topLeading) {
            if viewModel.title.isEmpty {
                Text(viewModel.placeholder)
                    .titleFont()
                    .foregroundStyle(theme.textFieldPlaceholder)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottom) {
            Divider()
                .background(theme.textFieldUnderline)
                .offset(y: 6)
        }
        .overlay(alignment: .trailing) {
            if viewModel.titleSuggestion == .generating {
                ProgressView()
                    .tint(theme.subTitle)
            }
        }
        .onReceive(viewModel.didApplySuggestion) { _ in
            guard let titleTextView else { return }

            selectAll(in: titleTextView)
        }
    }

    /// Selects the whole title once the field has laid the text out, so the selection is
    /// drawn — whether focus just arrived or a suggestion replaced the title
    private func selectAll(in textView: BookmarkTitleTextView.TextView) {
        textView.onNextLayout { [weak textView] in
            guard let textView else { return }

            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument,
                                                            to: textView.endOfDocument)
        }
    }

    @ViewBuilder
    private var transcriptSection: some View {
        if viewModel.passage != nil || viewModel.isCapturingTranscript {
            section {
                HStack {
                    Text(viewModel.passage == nil ? L10n.bookmarkTranscriptAdding : L10n.transcript)

                    Spacer()

                    if viewModel.snippet != nil {
                        editTranscriptButton
                    }
                }
                .padding(.bottom, 4)
            } content: {
                if let passage = viewModel.passage {
                    transcript(passage)
                } else {
                    transcript(Self.transcriptPlaceholder)
                        .redacted(reason: .placeholder)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func transcript(_ text: String) -> some View {
        Text(text)
            .font(size: BookmarkTranscriptStyle.fontSize, style: .body, design: .serif)
            .lineSpacing(BookmarkTranscriptStyle.lineSpacing)
            .foregroundStyle(theme.title)
            .lineLimit(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Stands in for the passage while the transcript loads. The redaction blocks it out,
    /// so it's never read, it only gives the placeholder the shape of a passage.
    private static let transcriptPlaceholder = """
    The passage captured around this moment lands here once the episode transcript has \
    been fetched, and it runs long enough to fill out the four lines it is given.
    """

    private var editTranscriptButton: some View {
        Text(L10n.edit)
            .font(style: .footnote)
            .foregroundStyle(theme.editButton)
            .buttonize {
                isTitleFocused = false
                isEditingTranscript = true
            }
            .accessibilityLabel(L10n.bookmarkEditTranscriptTitle)
    }

    /// A generated title suggestion the user can tap to use
    private func suggestionButton(_ suggestion: String) -> some View {
        (Text(L10n.bookmarkSuggestionPrefix)
            .foregroundColor(theme.subTitle)
            + Text(suggestion)
            .foregroundColor(theme.editButton))
            .font(size: 13, style: .footnote, weight: .medium)
            .kerning(-0.4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonize {
                viewModel.suggestionTapped(suggestion)
            }
            .accessibilityLabel(L10n.bookmarkSuggestedTitle(suggestion))
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var saveButton: some View {
        Button(viewModel.saveButtonTitle) {
            viewModel.save()
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.saveButton, backgroundColor: theme.saveButtonBackground))
    }

    private var closeButton: some View {
        Button {
            viewModel.cancel()
        } label: {
            Image("close")
                .renderingMode(.template)
                .foregroundStyle(theme.closeButton)
        }
        .accessibilityLabel(L10n.accessibilityCloseDialog)
    }
}

// MARK: - BookmarkTitleTextView

/// The title field, as a text view that wraps onto as many lines as the title needs and
/// grows to fit them.
private struct BookmarkTitleTextView: UIViewRepresentable {
    @Binding var text: String

    /// Two-way, so the form can move focus away from the title, and the field can report
    /// the keyboard being dismissed
    @Binding var isFocused: Bool

    let textColor: UIColor
    let accentColor: UIColor

    /// Handed the text view as editing begins, so the title can be selected in it
    let onBeginEditing: (TextView) -> Void
    let onSubmit: () -> Void

    @ScaledMetricWithMaxSize(relativeTo: .title2, maxSize: BookmarkTitleStyle.maxTypeSize)
    private var fontSize: CGFloat = BookmarkTitleStyle.fontSize

    private var font: UIFont {
        .systemFont(ofSize: fontSize, weight: BookmarkTitleStyle.fontWeight)
    }

    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.delegate = context.coordinator
        textView.text = text
        // Set here as well as on update, so the first height the field is measured for
        // is the one the title is actually drawn at
        textView.font = font
        textView.backgroundColor = .clear
        // Lines the text up with the label above it and the underline below it
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        // The text view grows with its content instead, so the form scrolls as a whole
        textView.isScrollEnabled = false
        textView.returnKeyType = .done
        textView.accessibilityLabel = L10n.bookmarkTitleLabel
        return textView
    }

    func updateUIView(_ textView: TextView, context: Context) {
        context.coordinator.view = self

        if textView.text != text {
            textView.text = text
        }

        textView.font = font
        textView.textColor = textColor
        textView.tintColor = accentColor

        guard isFocused != textView.isFirstResponder else { return }

        // Deferred: editing begins the moment the text view takes focus, and reporting
        // that back while SwiftUI is still updating the view would be a state change
        // in the middle of one
        DispatchQueue.main.async {
            if isFocused {
                textView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
        }
    }

    /// Asks the text view how tall it needs to be for the width it's offered
    func sizeThatFits(_ proposal: ProposedViewSize, uiView textView: TextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }

        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    /// A text view that can be asked to run work once its text has been laid out
    class TextView: UITextView {
        private var afterLayout: (() -> Void)?

        /// Runs `work` after the next layout pass, so a selection made against the text
        /// is drawn rather than dropped by the layout that follows it. Only the latest
        /// piece of work is kept, so repeated calls can't stack up.
        func onNextLayout(_ work: @escaping () -> Void) {
            afterLayout = work
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            guard window != nil, bounds.width > 0, let afterLayout else { return }

            self.afterLayout = nil
            // Out of the layout pass the work would otherwise be changing the text view in
            DispatchQueue.main.async(execute: afterLayout)
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var view: BookmarkTitleTextView

        init(view: BookmarkTitleTextView) {
            self.view = view
        }

        func textViewDidChange(_ textView: UITextView) {
            view.text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            view.isFocused = true

            guard let textView = textView as? TextView else { return }

            view.onBeginEditing(textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            view.isFocused = false
        }

        /// Return saves the bookmark, as it did when this was a single line field. Line
        /// breaks arriving any other way — pasted or dictated — are folded into spaces,
        /// since the title is drawn on one line everywhere it's listed.
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                view.onSubmit()
                return false
            }

            guard text.rangeOfCharacter(from: .newlines) != nil,
                  let replacedRange = textView.textRange(for: range) else { return true }

            textView.replace(replacedRange, withText: text.singleLine)
            view.text = textView.text
            return false
        }
    }
}

// MARK: - Theme

private extension BookmarkEditTheme {
    var editButton: Color { textFieldAccent }
}

// MARK: - Private Extensions

/// How the title reads, both in the field and in the placeholder standing in for it
private enum BookmarkTitleStyle {
    static let fontSize: CGFloat = 24
    static let fontWeight: UIFont.Weight = .bold
    static let maxTypeSize: DynamicTypeSize = .accessibility2
}

private extension View {
    func titleFont() -> some View {
        font(size: BookmarkTitleStyle.fontSize, style: .title2, weight: .bold)
    }
}

private extension UITextView {
    /// The range of text a delegate's `NSRange` points at
    func textRange(for range: NSRange) -> UITextRange? {
        guard let start = position(from: beginningOfDocument, offset: range.location),
              let end = position(from: start, offset: range.length) else { return nil }

        return textRange(from: start, to: end)
    }
}

private extension String {
    /// The text on a single line, with each run of line breaks standing in as one space
    var singleLine: String {
        components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Preview

struct BookmarkEditView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkEditView(viewModel: .init(manager: .init(),
                                          bookmark: Self.previewBookmark(title: "Hello", time: 3600, created: .now),
                                          state: .adding),
                         theme: .init(episode: nil))
            .setupDefaultEnvironment()
    }
}
