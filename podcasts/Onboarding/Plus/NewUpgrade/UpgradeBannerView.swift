import SwiftUI

struct UpgradeBannerView: View {
    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: PlusLandingViewModel

    var body: some View {
        VStack(spacing: 12) {
            SubscriptionBadge(tier: .plus)
            Text(L10n.upgradeAccountTitle)
                .foregroundStyle(theme.primaryText01)
                .font(size: 18, style: .headline, weight: .bold)
                .multilineTextAlignment(.center)
            Text(L10n.upgradeAccountInfo)
                .foregroundStyle(theme.primaryText01)
                .font(size: 13, style: .footnote, weight: .regular)
                .multilineTextAlignment(.center)
            SubscriptionPurchaseButton(viewModel: viewModel) {

            }
        }
        .padding(16)
        .background(theme.primaryUi01)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 1.5, x: 0, y: 1)
        .padding(16)
        .background(theme.primaryUi03)
    }
}
