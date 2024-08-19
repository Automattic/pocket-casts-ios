import SwiftUI
import PocketCastsServer

struct PlusPaywallFeaturesCarousell: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    let tier: UpgradeTier

    private var title: some View {
        Text(tier.header)
            .font(size: 22.0, style: .body, weight: .bold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
    }

    private var badge: some View {
        SubscriptionBadge(tier: tier.tier, displayMode: .gradient, foregroundColor: .black)
            .padding(.bottom, 12)
    }

    var body: some View {
        ScrollView {
            badge
            title
            Rectangle()
                .fill(.red)
                .frame(height: 394)
        }
    }
}

#Preview {
    PlusPaywallFeaturesCarousell(viewModel: PlusLandingViewModel(source: .login), tier: .plus)
}
