import SwiftUI

struct CancelConfirmationView: View {
    @EnvironmentObject var theme: Theme
    private let rows: [Row]

    let viewModel: CancelConfirmationViewModel

    init(viewModel: CancelConfirmationViewModel) {
        self.viewModel = viewModel

        // Make sure the expiration date doesn't wrap
        let expiration = viewModel.expirationDate?.nonBreakingSpaces()

        self.rows = [
            .init(imageName: "dollar-recycle-gold", text: L10n.cancelConfirmSubExpiry(expiration ?? L10n.cancelConfirmSubExpiryDateFallback), highlight: expiration),
            .init(imageName: "locked-large", text: L10n.cancelConfirmItemPlus),
            .init(imageName: "folder-locked", text: L10n.cancelConfirmItemFolders),
            .init(imageName: "remove_from_cloud", text: L10n.cancelConfirmItemUploads),
            .init(imageName: "about_website", text: L10n.cancelConfirmItemWebPlayer),
        ]
    }

    var body: some View {
        ScrollViewIfNeeded {
            VStack(spacing: Constants.padding.vertical) {
                header

                // List view
                VStack(alignment: .leading, spacing: Constants.padding.vertical) {
                    ForEach(rows) { row in
                        ListRow(row.text, image: row.imageName, highlightedText: row.highlight)
                    }
                }

                Spacer()

                // Bottom buttons
                VStack {
                    shadowDivider
                    buttons
                }

            }.padding([.leading, .trailing], Constants.padding.horizontal)
        }.background(color(for: .background).ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image(AppTheme.paymentFailedImageName())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)

            Text(L10n.cancelSubscription)
                .font(style: .title, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(color(for: .text))
                .padding(.bottom, 5)

            Text(L10n.cancelConfirmSubtitle)
                .font(style: .headline, weight: .medium, maxSizeCategory: .extraExtraExtraLarge)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(color(for: .subtitle))
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(L10n.cancelConfirmStayButtonTitle) {
            viewModel.goBackTapped()
        }.buttonStyle(RoundedButtonStyle(theme: theme))

        Button(L10n.cancelConfirmCancelButtonTitle) {
            viewModel.cancelTapped()
        }
        .buttonStyle(SimpleTextButtonStyle(theme: theme, textColor: .cancelButton))
        // Reduce the padding a bit to make it look more visually centered
        .padding([.top, .bottom], -5)
    }

    private var shadowDivider: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .foregroundColor(color(for: .background))
                .frame(height: Constants.shadowRadius * 2)
                .shadow(color: color(for: .divider).opacity(0.15), radius: Constants.shadowRadius, x: 0, y: -Constants.shadowRadius)
                // Clip the bottom part of the shadow off
                .mask(Rectangle().padding(.top, -Constants.shadowRadius * 4))

            divider.opacity(0.5)
        }
        // Apply a negative padding to make the view stretch to the full width of the view ignoring the parents padding
        .padding([.leading, .trailing], -Constants.padding.horizontal)
        .padding(.bottom, 10)
    }

    private var divider: some View {
        Divider().overlay(color(for: .divider))
    }

    private func color(for style: ThemeStyle) -> Color {
        AppTheme.color(for: style, theme: theme)
    }

    private enum Constants {
        enum padding {
            static let horizontal = 24.0
            static let vertical = 20.0
        }
        static let shadowRadius = 2.0
    }

    /// Internal model for the rows
    private struct Row: Identifiable {
        let imageName: String
        let text: String
        let highlight: String?

        init(imageName: String, text: String, highlight: String? = nil) {
            self.imageName = imageName
            self.text = text
            self.highlight = highlight
        }

        // Identifiable makes using ForEach cleaner
        var id: String { imageName }
    }
}

// MARK: - Style configuration
private extension ThemeStyle {
    static let background = Self.primaryUi01
    static let text = Self.primaryText01

    static let subtitle = Self.primaryText02
    static let list = Self.primaryText01
    static let divider = Self.primaryUi05Selected

    static let cancelButton = Self.support05

    static let iconColor = Self.primaryIcon01
    static let highlightColor = Self.primaryIcon01
}

// MARK: - Private: Views

private struct ListRow: View {
    @EnvironmentObject var theme: Theme

    let title: String
    let image: String
    let highlightedText: String?

    init(_ title: String, image: String, highlightedText: String? = nil) {
        self.title = title
        self.image = image
        self.highlightedText = highlightedText
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 24)
                .foregroundColor(AppTheme.color(for: .iconColor, theme: theme))
                .padding(.top, 3)

            HighlightedText(title)
                .font(.body.leading(.loose))
                .highlight(highlightedText) { _ in
                    .init(weight: .medium, color: AppTheme.color(for: .highlightColor, theme: theme))
                }
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(AppTheme.color(for: .text, theme: theme))
        }
    }
}
