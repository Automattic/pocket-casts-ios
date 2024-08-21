import SwiftUI
import PocketCastsServer

struct PlusPaywallFeaturesCarousell: View {
    let tier: UpgradeTier

    private var cards: [FeatureCards] {
        return [
            FeatureCards(id: UUID()),
            FeatureCards(id: UUID()),
            FeatureCards(id: UUID())
        ]
    }

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
                Rectangle()
                    .fill(.red)
                    .frame(height: 394)
                    .id(item.id)
            }
            .carouselItemSpacing(16)
            .carouselPeekAmount(.constant(proxy.size.width - 349))
            .carouselScrollEnabled(!cards.isEmpty)
            .padding(.leading, 20)
        }
    }

    var body: some View {
        ScrollView {
            badge
            title
            carousel
                .frame(height: 394)
        }
    }

    private enum Constants {
        static let bottomPadding = 16.0

        static let badgeBottomPadding = 12.0

        static let titleSize = 22.0
        static let titleLineLimit = 2
        static let titleHPadding = 32.0
        static let titleBottomPadding = 40.0
    }

    private struct FeatureCards: Identifiable {
        var id: UUID
    }
}

#Preview {
    PlusPaywallFeaturesCarousell(tier: .plus)
        .background(.black)
}
