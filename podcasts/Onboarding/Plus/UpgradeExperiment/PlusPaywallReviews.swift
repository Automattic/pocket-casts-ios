import SwiftUI

struct PlusPaywallReviews: View {
    let tier: UpgradeTier

    private var header: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("“Quite simply the best way to listen to podcasts”")
                .font(size: 22, style: .body, weight: .bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Text("See why people have upgraded to Plus")
                .font(size: 14, style: .body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Constants.textColor)
                .padding(.top, 8.0)
        }
    }

    private var badge: some View {
        SubscriptionBadge(tier: tier.tier, displayMode: .gradient, foregroundColor: .black)
            .padding(.top, 16.0)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 0) {
                header
                ZStack {
                    badge
                }
            }
            .padding(.horizontal, 20.0)
            .frame(maxWidth: .infinity)
        }
        .background(.black)
        .frame(width: .infinity)
    }

    private enum Constants {
        static let textColor = Color(hex: "#B8C3C9")
    }
}

#Preview {
    PlusPaywallReviews(tier: .plus)
}
