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

    @State private var titleTextField: UITextField?

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
        .animation(.easeInOut(duration: 0.2), value: viewModel.passage)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCapturingTranscript)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .padding()
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(viewModel.headerTitle)
        .navigationBarTitleDisplayMode(.inline)
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
            .onReceive(UITextField.textDidBeginEditingNotification.publisher()) { notification in
                guard let textField = notification.object as? UITextField else { return }
                titleTextField = textField
                selectAllTitle()
            }
            .onReceive(viewModel.didApplySuggestion) { _ in
                selectAllTitle()
            }
            .onSubmit {
                viewModel.save()
            }
    }

    /// Selects the whole title after a short delay, so the selection reliably appears
    /// once the field has settled — whether focus just arrived or a suggestion was applied
    private func selectAllTitle() {
        guard let titleTextField else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            titleTextField.selectedTextRange = titleTextField.textRange(from: titleTextField.beginningOfDocument, to: titleTextField.endOfDocument)
        }
    }

    @ViewBuilder
    private var transcriptSection: some View {
        if viewModel.passage != nil || viewModel.isCapturingTranscript {
            section {
                HStack {
                    Text(L10n.transcript)

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
