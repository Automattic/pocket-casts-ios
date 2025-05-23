import SwiftUI
import PocketCastsServer

struct PlusPaywallFeaturesCarousell: View {
    let tier: UpgradeTier

    private let cards = FeatureCardItem.allCases

    private var title: some View {
        Text(tier.header)
            .font(size: Constants.titleSize, style: .body, weight: .bold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(Constants.titleLineLimit)
            .padding(.horizontal, Constants.titleHPadding)
            .padding(.bottom, Constants.bottomPadding)
    }

    private var badge: some View {
        SubscriptionBadge(tier: tier.tier, displayMode: .gradient, foregroundColor: .black)
            .padding(.bottom, Constants.badgeBottomPadding)
    }

    private var carousel: some View {
        GeometryReader { proxy in
            HorizontalCarousel(items: cards) { item in
                PlusPaywallFeatureCard(item: item)
                    .frame(height: Constants.cardHeight)
                    .id(item.id)
            }
            .carouselItemSpacing(Constants.bottomPadding)
            .carouselPeekAmount(.constant(proxy.size.width - Constants.carouselTotalWSpace))
            .carouselScrollEnabled(!cards.isEmpty)
            .padding(.leading, Constants.carouselLeadingPadding)
        }
    }

    var body: some View {
        ScrollView {
            badge
            title
            carousel
                .frame(height: Constants.cardHeight)
        }
    }

    private enum Constants {
        static let bottomPadding = 16.0

        static let badgeBottomPadding = 12.0

        static let titleSize = 22.0
        static let titleLineLimit = 2
        static let titleHPadding = 32.0
        static let titleBottomPadding = 40.0

        static var cardHeight = 394.0
        static var carouselLeadingPadding = 20.0
        static var carouselTotalWSpace = 349.0
    }
}

#Preview {
    PlusPaywallFeaturesCarousell(tier: .plus)
        .background(.black)
}
