import PocketCastsDataModel
import SwiftUI

/// The add/edit bookmark sheet, with a generated title suggestion when one is available.
struct BookmarkEditView: View {
    @ObservedObject var viewModel: BookmarkEditViewModel
    @ObservedObject var theme: BookmarkEditTheme

    @FocusState private var isTitleFocused: Bool

    /// The title is only focused the first time the form appears, so coming back from
    /// the transcript editor doesn't pop the keyboard and select the title again
    @State private var hasFocusedTitle = false

    @State private var isEditingTranscript = false

    var body: some View {
        NavigationStack {
            form
                .navigationDestination(isPresented: $isEditingTranscript) {
                    transcriptEditor
                }
        }
    }

    // MARK: - Views

    private var form: some View {
        VStack(spacing: 0) {
            VStack(spacing: 32) {
                titleSection
                transcriptSection
            }

            Spacer(minLength: 32)

            saveButton
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.snippet?.text)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCapturingTranscript)
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(viewModel.headerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                closeButton
            }

            // The sheet is painted in the player's colors, which the bar's own title
            // knows nothing about
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
            BookmarkTranscriptEditView(transcript: transcript, selection: $viewModel.transcriptRange, theme: theme)
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

    /// A section of the form, e.g. the title field. The header is styled as a label, so
    /// a section that only needs one passes its `Text` and nothing else.
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

    /// An empty line of the same font pins the field to a single line height, so it
    /// doesn't jump around as the text scales down to fit
    private var titleField: some View {
        ZStack {
            Text(" ")
                .titleFont()
                .frame(maxWidth: .infinity)
                .hidden()
            textField
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
    }

    private var textField: some View {
        let prompt = Text(viewModel.placeholder).foregroundColor(theme.textFieldPlaceholder)

        return TextField(viewModel.placeholder, text: $viewModel.title, prompt: prompt)
            .textFieldStyle(.plain)
            .titleFont()
            .foregroundStyle(theme.textField)
            .accentColor(theme.textFieldAccent)
            .focused($isTitleFocused)
            .selectAllOnFocus()
            .onSubmit {
                viewModel.save()
            }
    }

    /// The transcript the title was generated from, so the user can see the captured
    /// moment and pick a different passage
    @ViewBuilder
    private var transcriptSection: some View {
        if viewModel.snippet != nil || viewModel.isCapturingTranscript {
            section {
                HStack {
                    Text(L10n.bookmarkTranscriptCaptured)

                    Spacer()

                    if viewModel.snippet != nil {
                        editTranscriptButton
                    }
                }
                // Set in towards the passage below, which its own padding insets
                .padding(.horizontal, 8)
            } content: {
                if let snippet = viewModel.snippet {
                    transcript(snippet.text)
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
            .padding(16)
            .background(theme.transcriptBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Stands in for the passage while the transcript loads. It's never read: the
    /// redaction blocks it out, it only gives the placeholder the shape of a passage.
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
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text(suggestion)
                .lineLimit(2)
        }
        .font(style: .callout)
        .foregroundStyle(theme.subTitle)
        .buttonize {
            viewModel.applySuggestion(suggestion)
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

// MARK: - Theme

private extension BookmarkEditTheme {
    var transcriptBackground: Color { theme.playerContrast06 }
    var editButton: Color { textFieldAccent }
}

// MARK: - Private Extensions

private extension View {
    func titleFont() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .font(size: 24, style: .title2, weight: .bold)
    }

    /// Selects all the text when the text field gains focus
    func selectAllOnFocus() -> some View {
        self.onReceive(UITextField.textDidBeginEditingNotification.publisher()) { notification in
            guard let textField = notification.object as? UITextField else {
                return
            }

            // Select after a delay because there's a bug where the selection won't appear if the text is too long
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            }
        }
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
