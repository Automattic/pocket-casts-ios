import SwiftUI

struct UpgradeBannerView: View {
    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: UpgradeAccountViewModel

    @State var isPresented: Bool = false

    let onSubscribeTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            SubscriptionBadge(tier: .plus, displayMode: .plain)
            Text(L10n.upgradeAccountTitle)
                .foregroundStyle(theme.primaryText01)
                .font(size: 18, style: .body, weight: .bold)
                .multilineTextAlignment(.center)
            Text(L10n.upgradeAccountInfo)
                .foregroundStyle(theme.primaryText02)
                .font(size: 13, style: .body, weight: .regular)
                .multilineTextAlignment(.center)
            SubscriptionPurchaseButton(viewModel: viewModel) {
                onSubscribeTap?()
            }
            .frame(maxWidth: 440)
        }
        .padding(16)
        .background(theme.primaryUi01)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 1.5, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(theme.primaryUi03)
    }
}
