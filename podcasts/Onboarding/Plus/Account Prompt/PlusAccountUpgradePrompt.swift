import SwiftUI
import PocketCastsServer

struct PlusAccountUpgradePrompt: View {
    typealias ProductInfo = PlusPricingInfoModel.PlusProductPricingInfo

    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlusAccountPromptViewModel

    @State private var currentPage = 0
    @State private var waitingToLoad = false

    private let products: [ProductInfo]

    /// Allows UIKit to listen for content size changes
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

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
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    SubscriptionBadge(tier: product.identifier.subscriptionTier)
                        .padding(.bottom, 10)
                    SubscriptionPriceAndOfferView(product: product, mainTextColor: theme.primaryText01, secondaryTextColor: theme.primaryText02)
                    productFeatures[product.identifier].map {
                        ForEach($0) { feature in
                            HStack(spacing: 10) {
                                Image(feature.iconName)
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16)
                                    .foregroundColor(theme.primaryText01)

                                Text(feature.title)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(size: 14, style: .subheadline, weight: .medium)
                                    .foregroundColor(theme.primaryText01)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()
                            }.frame(maxWidth: .infinity)
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

    private let productFeatures: [Constants.IapProducts: [Feature]] = [
        .yearly: [
            .init(iconName: "plus-feature-desktop", title: L10n.plusMarketingDesktopAppsTitle),
            .init(iconName: "plus-feature-folders", title: L10n.plusMarketingFoldersAndBookmarksTitle),
            .init(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimit),
            .init(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
            .init(iconName: "plus-feature-themes", title: L10n.plusFeatureThemesIcons)
        ],

        .patronYearly: [
            .init(iconName: "patron-everything", title: L10n.patronFeatureEverythingInPlus),
            .init(iconName: "patron-early-access", title: L10n.patronFeatureEarlyAccess),
            .init(iconName: "plus-feature-cloud", title: L10n.patronCloudStorageLimit),
            .init(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            .init(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons)
        ]
    ]

    // MARK: - Model
    private struct Feature: Identifiable, Hashable {
        let iconName: String
        let title: String

        var id: String { title }
    }
}

extension Constants.IapProducts {
    var subscriptionTier: SubscriptionTier {
        switch self {
        case .monthly, .yearly:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var plan: Constants.Plan {
        switch self {
        case .monthly, .yearly:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var frequency: Constants.PlanFrequency {
        switch self {
        case .monthly, .patronMonthly:
            return .monthly
        case .yearly, .patronYearly:
            return .yearly
        }
    }

    var productInfo: Constants.ProductInfo {
        .init(plan: plan, frequency: frequency)
    }
}

struct PlusAccountUpgradePrompt_Previews: PreviewProvider {
    static var previews: some View {
        PlusAccountUpgradePrompt(viewModel: .init())
            .setupDefaultEnvironment()
    }
}
