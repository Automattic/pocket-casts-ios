import PocketCastsDataModel
import SwiftUI

/// The add/edit bookmark sheet, with a generated title suggestion when one is available.
struct BookmarkEditView: View {
    @ObservedObject var viewModel: BookmarkEditViewModel
    @ObservedObject var theme: BookmarkEditTheme

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 18) {
                header
                titleSection
                transcriptSection
                Spacer()
                saveButton
            }
            .padding(.top, 18)
            .animation(.easeInOut(duration: 0.2), value: viewModel.transcript)

            closeButton
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.background)
        .onAppear {
            isTitleFocused = true
        }
    }

    // MARK: - Views

    @ViewBuilder
    private var header: some View {
        Text(viewModel.headerTitle)
            .foregroundStyle(theme.title)
            .font(size: 19, style: .title3, weight: .bold)

        Text(viewModel.headerSubTitle)
            .foregroundStyle(theme.subTitle)
            .font(style: .callout)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            section(L10n.bookmarkTitleLabel) {
                titleField
            }

            if case .available(let suggestion) = viewModel.titleSuggestion {
                suggestionButton(suggestion)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.titleSuggestion)
    }

    /// A labelled section of the form, e.g. the title field
    private func section(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(style: .footnote)
                .foregroundStyle(theme.subTitle)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// An empty line of the same font pins the field to a single line height, so it
    /// doesn't jump around as the text scales down to fit
    private var titleField: some View {
        Text(" ")
            .titleFont()
            .frame(maxWidth: .infinity)
            .hidden()
            .overlay { textField }
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

    /// The transcript the title was generated from, so the user can see the captured moment
    @ViewBuilder
    private var transcriptSection: some View {
        if let transcript = viewModel.transcript {
            section(L10n.bookmarkTranscriptCaptured) {
                Text(transcript)
                    .font(style: .subheadline)
                    .foregroundStyle(theme.title)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(theme.transcriptBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
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
        Image("close")
            .renderingMode(.template)
            .foregroundStyle(theme.closeButton)
            .buttonize {
                viewModel.cancel()
            }
    }
}

// MARK: - Theme

private extension BookmarkEditTheme {
    var transcriptBackground: Color { theme.playerContrast06 }
}

// MARK: - Private Extensions

private extension View {
    func titleFont() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.5)
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
