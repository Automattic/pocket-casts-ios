import SwiftUI

struct FeaturesCarousel: View {
    let currentIndex: Binding<Int>

    let currentSubscriptionPeriod: Binding<PlanFrequency>

    let viewModel: PlusLandingViewModel

    let tiers: [UpgradeTier]

    let showInlinePurchaseButton: Bool

    @State var calculatedCardHeight: CGFloat?
    @State var calculatedCardMaxHeight: CGFloat?

    var body: some View {
        // Store the calculated card heights
        var cardHeights: [CGFloat] = []

        HorizontalCarousel(currentIndex: currentIndex, items: tiers) {
            UpgradeCard(tier: $0, currentPrice: currentSubscriptionPeriod, subscriptionInfo: viewModel.pricingInfo(for: $0, frequency: currentSubscriptionPeriod.wrappedValue), showPurchaseButton: showInlinePurchaseButton)
                .overlay(
                    // Calculate the height of the card after it's been laid out
                    GeometryReader { proxy in
                        Action {
                            // Add the calculated height to the array
                            cardHeights.append(proxy.size.height)

                            // Determine the max height only once we've calculated all the heights
                            if cardHeights.count == tiers.count {
                                calculatedCardHeight = cardHeights.max()

                                if (calculatedCardHeight ?? 0) > (calculatedCardMaxHeight ?? 0) {
                                    calculatedCardMaxHeight = calculatedCardHeight
                                }

                                // Reset the card heights so any view changes won't use old data
                                cardHeights = []
                            }
                        }
                    }
                )
                .frame(maxHeight: calculatedCardHeight, alignment: .top)
        }
        .carouselPeekAmount(.constant(tiers.count > 1 ? ViewConstants.peekAmount : 0))
        .carouselItemSpacing(ViewConstants.spacing)
        .carouselScrollEnabled(tiers.count > 1)
        // Maintain the largest height
        .frame(height: calculatedCardMaxHeight, alignment: .top)
        .padding(.leading, 30)
    }

    private enum ViewConstants {
        static let peekAmount: Double = 20
        static let spacing: Double = 30
    }
}
