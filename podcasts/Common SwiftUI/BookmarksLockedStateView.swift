import PocketCastsServer
import SwiftUI

/// A view that displays the locked empty state for a `PaidFeature`
struct BookmarksLockedStateView<Style: EmptyStateViewStyle>: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var style: Style
    @StateObject private var upgradeModel: BookmarksUpgradeViewModel

    init(style: Style, feature: PaidFeature) {
        self.style = style
        _upgradeModel = .init(wrappedValue: .init(feature: feature))
    }

    var body: some View {
        EmptyStateView(title: { lockedTitleView }, message: L10n.noBookmarksMessage, actions: [
            .init(title: upgradeModel.upgradeLabel, action: {
//                upgradeModel.upgradeTapped()

                theme.cycleThemeForTesting()
            })
        ], style: style)
    }

    /// Displays the Pocket Casts logo and badge for the required tier
    private var lockedTitleView: some View {
        HStack(spacing: 8) {
            Image("pocket-casts-text-logo-horizontal")
                .renderingMode(.template)
                .foregroundStyle(style.title)

            PaidFeatureBadge(feature: upgradeModel.feature)
        }
    }

    /// Helper to display the tier badge for the feature
    private struct PaidFeatureBadge: View {
        let feature: PaidFeature

        private var displayMode: SubscriptionBadge.DisplayMode {
            feature.tier == .plus ? .gradient : .black
        }

        var body: some View {
            SubscriptionBadge(tier: feature.tier,
                              displayMode: displayMode,
                              fontSize: 16)
        }
    }
}

// MARK: - Upgrade Model

private class BookmarksUpgradeViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature

    init(feature: PaidFeature) {
        self.feature = feature
        super.init()
    }

    var upgradeLabel: String {
        guard let product = product(for: feature.tier) else {
            return L10n.upgradeAccount
        }

        return upgradeLabel(for: product)
    }

    func upgradeTapped() {
        upgradeTapped(with: product(for: feature.tier))
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        let controller = feature.upgradeController(source: "bookmarks_locked_state")
        parentController.presentFromRootController(controller)
    }

    private func product(for tier: SubscriptionTier) -> PlusProductPricingInfo? {
        products.first(where: { $0.identifier.subscriptionTier == tier })
    }
}
