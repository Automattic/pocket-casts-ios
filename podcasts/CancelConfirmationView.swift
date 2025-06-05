import SwiftUI
import PocketCastsUtils

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
            .init(imageName: "folder-cross", text: L10n.cancelConfirmItemFolders),
            .init(imageName: "remove_from_cloud", text: L10n.cancelConfirmItemUploads),
            .init(imageName: "filter_clock", text: L10n.cancelConfirmItemHistory)
        ]
    }

    var body: some View {
        ScrollViewIfNeeded {
            VStack(spacing: Constants.padding.vertical) {
                let bottomPadding = FeatureFlag.winback.enabled ? 20.0 : 0.0
                header
                    .padding(.bottom, bottomPadding)

                // List view
                let spacing = FeatureFlag.winback.enabled ? 0 : Constants.padding.vertical
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(rows) { row in
                        let bottomPadding: CGFloat = FeatureFlag.winback.enabled ? 24.0 : 0
                        ListRow(row.text, image: row.imageName, highlightedText: row.highlight)
                            .padding(.bottom, bottomPadding)
                    }
                }

                Spacer()

                // Bottom buttons
                let buttonsSpacing: CGFloat? = FeatureFlag.winback.enabled ? 0 : nil
                VStack(spacing: buttonsSpacing) {
                    if !FeatureFlag.winback.enabled {
                        shadowDivider
                    }
                    buttons
                }

            }
            .padding([.leading, .trailing], Constants.padding.horizontal)
        }
        .background(color(for: .background).ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 0) {
            if !FeatureFlag.winback.enabled {
                Image(AppTheme.paymentFailedImageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
            }
            let topPadding = FeatureFlag.winback.enabled ? 44.0 : 0.0
            let bottomPadding = FeatureFlag.winback.enabled ? 4.0 : 5.0
            Text(L10n.cancelConfirmTitle)
                .font(style: .title, weight: .bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(color(for: .text))
                .padding(.bottom, bottomPadding)
                .padding(.top, topPadding)
            let fontWeight: Font.Weight = FeatureFlag.winback.enabled ? .regular : .medium
            let fontSize: Double? = FeatureFlag.winback.enabled ? 15.0 : nil
            let style: Font.TextStyle = FeatureFlag.winback.enabled ? .body : .headline
            Text(L10n.cancelConfirmSubtitle)
                .font(size: fontSize, style: style, weight: fontWeight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(color(for: .subtitle))
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(L10n.cancelConfirmStayButtonTitle) {
            viewModel.goBackTapped()
        }
        .buttonStyle(RoundedButtonStyle(theme: theme))

        let topPadding = FeatureFlag.winback.enabled ? 15.0 : -5
        let bottomPadding = FeatureFlag.winback.enabled ? 0.0 : -5
        Button(L10n.cancelConfirmCancelButtonTitle) {
            viewModel.cancelTapped()
        }
        .buttonStyle(SimpleTextButtonStyle(theme: theme, textColor: .cancelButton))
        // Reduce the padding a bit to make it look more visually centered
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
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
    @Environment(\.sizeCategory) private var sizeCategory

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
            let topPadding = FeatureFlag.winback.enabled ? 0.0 : 3.0
            Image(image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .scaleFactor(for: sizeCategory)
                .frame(width: 24, height: 24)
                .foregroundColor(AppTheme.color(for: .iconColor, theme: theme))
                .padding(.top, topPadding)

            let uiFont = UIFont.font(ofSize: 15.0, scalingWith: .body)
            let font: Font = FeatureFlag.winback.enabled ? Font(uiFont) : .body.leading(.loose)
            HighlightedText(title)
                .font(font)
                .highlight(highlightedText) { _ in
                    if FeatureFlag.winback.enabled {
                        HighlightedText.HighlightStyle(weight: .regular, color: AppTheme.color(for: .highlightColor, theme: theme))
                    } else {
                        HighlightedText.HighlightStyle(weight: .medium, color: AppTheme.color(for: .highlightColor, theme: theme))
                    }
                }
                .modify {
                    if FeatureFlag.winback.enabled {
                        // This is to apply the right font to the highlighted text,
                        // even when the `highlightedText` is nil
                        $0.font(size: 15.0, style: .body, weight: .regular)
                    } else {
                        $0
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(AppTheme.color(for: .text, theme: theme))
        }
    }
}
