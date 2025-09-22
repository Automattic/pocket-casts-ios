import SwiftUI
import PocketCastsServer
import Kingfisher
import PocketCastsUtils

class BannerAdModel: ObservableObject {
    let adText: String
    let imageURL: URL?
    let adLabel: String
    let titleLabel: String
    let adID: String
    let location: String
    let onLinkTap: (() -> Void)?

    fileprivate init(adText: String, imageURL: URL, linkTitle: String, adID: String, location: String, titleLabel: String = L10n.bannerAdsInfoLabel, onLinkTap: (() -> Void)? = nil) {
        self.adText = adText
        self.imageURL = imageURL
        self.adLabel = titleLabel
        self.titleLabel = linkTitle
        self.onLinkTap = onLinkTap
        self.adID = adID
        self.location = location
    }

    init(promotion: BlazePromotion, onLinkTap: (() -> Void)? = nil) {
        self.adText = promotion.text
        self.imageURL = promotion.imageURL
        self.adLabel = L10n.bannerAdsInfoLabel
        self.titleLabel = promotion.urlTitle
        self.onLinkTap = onLinkTap
        self.adID = promotion.id
        self.location = promotion.location.rawValue
    }
}

struct BannerAdView: View {
    struct Colors {
        let background: Color
        let adText: Color
        let titleLabel: Color
        let adLabelBackground: Color
        let adLabel: Color
        let icon: Color
        let border: Color?

        static func playerColors(_ theme: Theme) -> Self {
            return Self(
                background: theme.playerContrast06,
                adText: theme.playerContrast01,
                titleLabel: PlayerColorHelper.playerHighlightColor01(for: .dark).color,
                adLabelBackground: theme.playerContrast06,
                adLabel: theme.playerContrast01,
                icon: theme.playerContrast02,
                border: nil
            )
        }

        static func podcastList(_ theme: Theme) -> Self {
            return Self(
                background: .clear,
                adText: theme.primaryText01,
                titleLabel: theme.primaryInteractive01,
                adLabelBackground: theme.primaryInteractive01,
                adLabel: theme.primaryUi02Active,
                icon: theme.primaryIcon02,
                border: theme.primaryUi05
            )
        }
    }

    @ObservedObject var model: BannerAdModel
    private let colors: Colors
    @EnvironmentObject var theme: Theme
    @Environment(\.sizeCategory) private var sizeCategory

    // Keep banner text small only when Display Zoom is enabled.
    var maxSizeCategory: UIContentSizeCategory {
        A11y.isDisplayZoomed ? .small : .accessibilityMedium
    }

    init(model: BannerAdModel, colors: Colors) {
        self.model = model
        self.colors = colors
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.background)

            if let border = colors.border {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(border, lineWidth: 1)
            }

            adContent()
        }
        .padding(.vertical, 4)
        .onAppear {
            AnalyticsHelper.bannerImpression(adID: model.adID, location: model.location)
        }
        .onTapGesture {
            AnalyticsHelper.bannerTapped(adID: model.adID, location: model.location)
            model.onLinkTap?()
        }
    }

    @ViewBuilder func adContent() -> some View {
        HStack(alignment: .top, spacing: 16) {
            creative()
                .fixedSize()

            text()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)

            closeButton()
                .fixedSize()
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func creative() -> some View {
        AsyncImageView(url: model.imageURL!)
            .cornerRadius(4)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 86, height: 86)
    }

    @ViewBuilder func text() -> some View {
        VStack(alignment: .leading) {
            Text(model.adText)
                .font(size: 14, style: .subheadline, weight: .medium, maxSizeCategory: maxSizeCategory)
                .lineSpacing(-1)
                .foregroundColor(colors.adText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack(spacing: 4) {
                Text(model.adLabel)
                    .font(size: 8, style: .caption2, weight: .semibold, maxSizeCategory: maxSizeCategory)
                    .foregroundColor(colors.adLabel)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 2)
                    .background(colors.adLabelBackground)
                    .cornerRadius(2)

                Text(model.titleLabel)
                    .font(size: 12, style: .footnote, weight: .semibold, maxSizeCategory: maxSizeCategory)
                    .foregroundColor(colors.titleLabel)
            }
        }
    }

    @ViewBuilder func closeButton() -> some View {
        VStack {
            Button(action: {
                BannerAdReporter.show(for: model.adID, from: model.location)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .bold()
                    .foregroundStyle(colors.icon)
            }
            .padding(2)
            Spacer(minLength: 0)
        }
    }
}

#Preview("Light - Podcast List Theme") {
    BannerAdView(
        model: .init(
            adText: "Listen to your favorite books while supporting your local indie bookstore",
            imageURL: URL(string: "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg")!,
            linkTitle: "Libro.fm",
            adID: "test-ad-id",
            location: "test"
        ),
        colors: .podcastList(Theme(previewTheme: .light))
    )
    .environmentObject(Theme(previewTheme: .light))
    .padding(16)
    .frame(maxWidth: 400)
}

#Preview("Dark - Podcast List Theme") {
    BannerAdView(
        model: .init(
            adText: "Listen to your favorite books while supporting your local indie bookstore",
            imageURL: URL(string: "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg")!,
            linkTitle: "Libro.fm",
            adID: "test-ad-id",
            location: "test"
        ),
        colors: .podcastList(Theme(previewTheme: .light))
    )
    .environmentObject(Theme(previewTheme: .dark))
    .padding(16)
    .frame(maxWidth: 400)
}
