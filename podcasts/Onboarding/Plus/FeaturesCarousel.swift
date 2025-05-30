import SwiftUI

struct FeaturesCarousel: View {
    let currentIndex: Binding<Int>

    let currentSubscriptionPeriod: Binding<PlanFrequency>

    let viewModel: PlusLandingViewModel

    let tiers: [UpgradeTier]

    let showInlinePurchaseButton: Bool

    @State var calculatedCardHeight: CGFloat?
    @State var calculatedCardMaxHeight: CGFloat?
    @State private var cardHeights: [UpgradeTier.ID: CGFloat] = [:]

    var body: some View {
        HorizontalCarousel(currentIndex: currentIndex, items: tiers) { tier in
            UpgradeCard(tier: tier, currentPrice: currentSubscriptionPeriod, subscriptionInfo: viewModel.pricingInfo(for: tier, frequency: currentSubscriptionPeriod.wrappedValue), showPurchaseButton: showInlinePurchaseButton)
                .environmentObject(viewModel)
                .overlay(
                    GeometryReader { proxy in
                        Action {
                            cardHeights[tier.id] = proxy.size.height

                            if cardHeights.count == tiers.count {
                                calculatedCardHeight = cardHeights[tier.id]
                                calculatedCardMaxHeight = cardHeights.values.max()
                                cardHeights = [:]
                            }
                        }
                    }
                )
                .frame(maxHeight: calculatedCardHeight, alignment: .top)
        }
        .carouselPeekAmount(.constant(tiers.count > 1 ? ViewConstants.peekAmount : 0))
        .carouselItemSpacing(ViewConstants.spacing)
        .carouselScrollEnabled(tiers.count > 1)
        .frame(height: calculatedCardMaxHeight, alignment: .top)
        .padding(.leading, 30)
    }

    private enum ViewConstants {
        static let peekAmount: Double = 20
        static let spacing: Double = 30
    }
}
