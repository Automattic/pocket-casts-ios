import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct PlusAccountUpgradePrompt: View {
    typealias ProductInfo = PlusPricingInfoModel.PlusProductPricingInfo

    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlusAccountPromptViewModel
    @Environment(\.sizeCategory) private var sizeCategory

    @State private var currentPage = 0
    @State private var waitingToLoad = false

    private let products: [ProductInfo]

    /// Allows UIKit to listen for content size changes
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

    private var vSpacing: CGFloat {
        max(16.0, 16.0 * ScaleFactorModifier.scaleFactor(for: sizeCategory))
    }

    private var hSpacing: CGFloat {
        max(10.0, 10.0 * ScaleFactorModifier.scaleFactor(for: sizeCategory))
    }

    init(viewModel: PlusAccountPromptViewModel, contentSizeUpdated: ((CGSize) -> Void)? = nil) {
        self.viewModel = viewModel
        self.products = viewModel.products
        self.contentSizeUpdated = contentSizeUpdated
    }

    var body: some View {
        ContentSizeGeometryReader(content: { proxy in
            VStack(spacing: 0) {
                HorizontalCarousel(currentIndex: $currentPage, items: products) { item in
                    CarouselEqualHeightsView {
                        card(for: item, geometryProxy: proxy)
                            .frame(maxWidth: .infinity)
                    }
                }
                .carouselItemsToDisplay(1)
                .carouselPeekAmount(.constant(0))
                .carouselItemSpacing(0)
                .carouselScrollEnabled(products.count > 1)

                if products.count > 1 {
                    PageIndicatorView(numberOfItems: products.count, currentPage: currentPage)
                        .foregroundColor(theme.primaryText01)
                        .padding(.top, 10)
                }
            }
            .padding(.vertical, 20)
            .background(theme.primaryUi01)
        }, contentSizeUpdated: contentSizeUpdated)
    }

    @ViewBuilder
    func card(for product: ProductInfo, geometryProxy: GeometryProxy) -> some View {
        VStack(spacing: vSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    SubscriptionPriceAndOfferView(product: product, mainTextColor: theme.primaryText01, secondaryTextColor: theme.primaryText02)
                    productFeatures[product.identifier].map {
                        ForEach($0) { feature in
                            HStack(spacing: hSpacing) {
                                Image(feature.iconName)
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleFactor(for: sizeCategory)
                                    .frame(width: 16)
                                    .foregroundColor(theme.primaryText01)

                                UnderlineLinkTextView(feature.title)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(size: 14, style: .subheadline, weight: .medium)
                                    .foregroundColor(theme.primaryText01)
                                    .tint(theme.primaryText01)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            subscribeButton(for: product)
        }
        .padding(.horizontal, 16)
        .background(theme.primaryUi01)
    }

    @ViewBuilder
    private func subscribeButton(for product: ProductInfo) -> some View {
        let plan = product.identifier.plan
        let label = viewModel.upgradeLabel(for: product)

        // Only show loading if the user has tapped the button and is waiting
        let isLoading = waitingToLoad ? viewModel.priceAvailability != .available : false

        Button(label) {
            // Show a loading indicator on the button if we haven't loaded the prices yet
            waitingToLoad = true

            // Show the upgrade prompt
            viewModel.upgradeTapped(with: product)
        }
        .buttonStyle(PlusGradientFilledButtonStyle(isLoading: isLoading, plan: plan))
        .padding(.vertical, 10)
    }

    private let productFeatures: [IAPProductID: [Feature]] = [
        .yearly: ([
            (FeatureFlag.bannerAdPodcasts.enabled || FeatureFlag.bannerAdPlayer.enabled) ? .init(iconName: "unsubscribe", title: L10n.plusMarketingNoBannerAds) : nil,
            (FeatureFlag.generatedTranscripts.enabled) ? .init(iconName: "transcript", title: L10n.plusMarketingGeneratedTranscripts) : nil,
            .init(iconName: "plus-feature-folders", title: L10n.plusMarketingFoldersTitle),
            .init(iconName: "plus-feature-up-next-shuffle", title: L10n.plusMarketingUpNextShuffle),
            .init(iconName: "plus-feature-bookmarks", title: L10n.plusMarketingBookmarksTitle),
            PaidFeature.deselectChapters.tier == .plus ? .init(iconName: "rounded-selected", title: L10n.skipChapters) : nil,
            .init(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimit),
            .init(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
            FeatureFlag.slumber.enabled && FeatureFlag.upgradeExperiment.enabled ? Feature(iconName: "plus-feature-slumber", title: L10n.plusFeatureSlumberNew.newSlumberStudiosWithUrl) : nil,
            .init(iconName: "plus-feature-themes", title: L10n.plusFeatureThemesIcons),
            FeatureFlag.slumber.enabled && !FeatureFlag.upgradeExperiment.enabled ? Feature(iconName: "plus-feature-slumber", title: L10n.plusFeatureSlumber.slumberStudiosWithUrl) : nil,
            libroFmFeature()
        ]
            .compactMap { $0 }),

        .patronYearly: [
            .init(iconName: "patron-everything", title: L10n.patronFeatureEverythingInPlus),
            .init(iconName: "patron-early-access", title: L10n.patronFeatureEarlyAccess),
            PaidFeature.deselectChapters.tier == .patron ? .init(iconName: "rounded-selected", title: L10n.skipChapters) : nil,
            .init(iconName: "plus-feature-cloud", title: L10n.patronCloudStorageLimit),
            .init(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            .init(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            FeatureFlag.slumber.enabled ? Feature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude) : nil
        ]
            .compactMap { $0 }
    ]

    private static func libroFmFeature() -> Feature? {
        if FeatureFlag.libroFm.enabled {
            return Feature(iconName: "plus-feature-librofm", title: L10n.plusFeatureLibrofm.libroFmWithURL)
        }
        return nil
    }

    // MARK: - Model
    private struct Feature: Identifiable, Hashable {
        let iconName: String
        let title: String

        var id: String { title }
    }
}

extension IAPProductID {
    var subscriptionTier: SubscriptionTier {
        switch self {
        case .monthly, .yearly, .yearlyReferral:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var plan: Plan {
        switch self {
        case .monthly, .yearly, .yearlyReferral:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var frequency: PlanFrequency {
        switch self {
        case .monthly, .patronMonthly:
            return .monthly
        case .yearly, .patronYearly, .yearlyReferral:
            return .yearly
        }
    }

    var productInfo: ProductInfo {
        .init(plan: plan, frequency: frequency)
    }
}

struct PlusAccountUpgradePrompt_Previews: PreviewProvider {
    static var previews: some View {
        PlusAccountUpgradePrompt(viewModel: .init())
            .setupDefaultEnvironment()
    }
}
