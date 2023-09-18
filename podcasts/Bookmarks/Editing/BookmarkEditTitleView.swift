import Combine
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

struct BookmarkEditTitleView: View {
    @ObservedObject var viewModel: BookmarkEditViewModel
    @ObservedObject var theme: BookmarkEditTheme

    @State private var bookmarkTitle: String
    @State private var textFieldSize: CGSize = .zero
    @FocusState private var focusedField: Field?

    init(viewModel: BookmarkEditViewModel, theme: BookmarkEditTheme) {
        self.viewModel = viewModel
        self.theme = theme

        _bookmarkTitle = .init(initialValue: viewModel.originalTitle)
    }

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
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.background)
        .onChange(of: viewModel.didAppear) { _ in
            focusedField = .title
        }
    }

    // MARK: - Views

    /// The actual content of the view
    private var mainView: some View {
        VStack(spacing: EditConstants.padding) {
            headerView
            Spacer()
            textField
            Spacer()
            saveButton
        }
        .padding(.top, EditConstants.padding)
    }

    /// The title and subtitle views
    @ViewBuilder
    private var headerView: some View {
        Text(viewModel.headerTitle)
            .foregroundStyle(theme.title)
            .font(size: 19, style: .title3, weight: .bold)

        Text(viewModel.headerSubTitle)
            .foregroundStyle(theme.subTitle)
            .font(style: .callout)
    }

    /// A line that appears under the text field
    @ViewBuilder
    private var textFieldUnderline: some View {
        VStack {
            Spacer()

            Divider().background(theme.textFieldUnderline)
        }
        .offset(y: 6)
    }

    @ViewBuilder
    private var saveButton: some View {
        Button(viewModel.saveButtonTitle) {
            viewModel.save(title: bookmarkTitle)
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.saveButton, backgroundColor: theme.saveButtonBackground))
    }

    @ViewBuilder
    private var textField: some View {
        let prompt = Text(viewModel.placeholder).foregroundColor(theme.textFieldPlaceholder)

        ZStack {
            /// This looks really bad and I bet you may have questions...
            ///
            /// So, there's this _really_ fun bug that is causing the TextField's height to bounce between the max size
            /// and the scaled size, whicn causes the entire view to jump. Believe me I tried everything I could.
            ///
            /// So! to fix this I've crafted this monstrosity of code below. So here's what it does:
            ///
            /// - It creates an invisible Text view and a TextField with the same font, and min scaling
            /// - When the TextField changes the Text is also updated and will scale the same way the text field should
            /// - Since the Text view doesn't have the same bug we listen for content size changes
            /// - Then we sync the Text's height to the TextField to prevent it from jumping around.
            ///
            /// It works 🤷‍♀️
            ///
            /// Feel free to comment out the `.frame(height: textFieldSize.height)` to see the bug in action.
            ///
            ContentSizeReader(contentSize: $textFieldSize) {
                // Invisible text view just for calculating size
                Text(bookmarkTitle.isEmpty ? viewModel.placeholder : bookmarkTitle)
                    .applyTextStyle()
                    .foregroundStyle(.clear)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .background(textFieldUnderline)
            }

            TextField(viewModel.placeholder, text: $bookmarkTitle, prompt: prompt)
                .selectAllOnFocus()
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain)
                .applyTextStyle()
                .foregroundStyle(theme.textField)
                .accentColor(theme.textFieldAccent)

                // Force the height to be equal to the invisible text view
                .frame(height: textFieldSize.height)

                // Enforce the max length of the title
                .onChange(of: bookmarkTitle, perform: { newValue in
                    let max = Constants.Values.bookmarkMaxTitleLength
                    guard newValue.count > max else { return }

                    bookmarkTitle = String(newValue.prefix(max))
                })

                // Trigger the save action
                .onSubmit {
                    viewModel.save(title: bookmarkTitle)
                }
        }
    }

    // MARK: - Enums

    private enum Field {
        case title
    }

    private enum EditConstants {
        static let padding = 18.0
    }
}

// MARK: - Private Extensions

private extension View {
    func applyTextStyle() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .font(size: 31, style: .largeTitle, weight: .bold)
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

// MARK: - Theme

class BookmarkEditTheme: ThemeObserver {
    let episode: BaseEpisode?

    init(episode: BaseEpisode?) {
        self.episode = episode
    }

    var background: Color {
        PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme, episode: episode).color
    }

    var title: Color { theme.playerContrast01 }
    var subTitle: Color { theme.playerContrast02 }
    var closeButton: Color { theme.playerContrast01 }
    var textField: Color { theme.playerContrast01 }

    var textFieldAccent: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color
    }

    var textFieldPlaceholder: Color { theme.playerContrast05 }
    var textFieldUnderline: Color { theme.playerContrast05 }

    var saveButton: Color {
        saveButtonBackground.luminance() < 0.5 ? .white : .black
    }

    var saveButtonBackground: Color {
        PlayerColorHelper.playerHighlightColor01(for: .dark, episode: episode).color
    }
}

// MARK: - Preview

struct BookmarkEditTitleView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkEditTitleView(viewModel: .init(manager: .init(),
                                               bookmark: Self.previewBookmark(title: "Hello", time: 3600, created: .now),
                                               state: .adding), theme: .init(episode: nil)).setupDefaultEnvironment()
    }
}
