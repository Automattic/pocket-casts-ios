import PocketCastsServer
import SwiftUI

/// A view that displays the locked empty state for a `PaidFeature`
struct BookmarksLockedStateView<Style: EmptyStateViewStyle>: View {
    @ObservedObject var style: Style
    @StateObject private var upgradeModel: BookmarksUpgradeViewModel

    init(style: Style, feature: PaidFeature, source: BookmarkAnalyticsSource) {
        self.style = style

        _upgradeModel = .init(wrappedValue: .init(feature: feature, source: source))
    }

    private var message: String {
        let tierName: String
        switch upgradeModel.feature.tier {
        case .patron:
            tierName = L10n.patron
        case .plus:
            tierName = L10n.pocketCastsPlusShort
        case .none:
            tierName = L10n.pocketCastsPlusShort
        }

        return L10n.boomarksLockedMessage(tierName)
    }

    var body: some View {
        EmptyStateView(title: { lockedTitleView }, message: message, actions: [
            .init(title: upgradeModel.upgradeLabel, action: {
                upgradeModel.upgradeTapped()
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
    let bookmarksSource: BookmarkAnalyticsSource

    init(feature: PaidFeature, source: BookmarkAnalyticsSource) {
        self.feature = feature
        self.bookmarksSource = source
        super.init()
    }

    var upgradeLabel: String {
        guard product(for: feature.tier)?.freeTrialDuration != nil else {
            return L10n.upgradeToPlan(feature.tier == .patron ? L10n.patron : L10n.pocketCastsPlusShort)
        }

        return L10n.startFreeTrial
    }

    func upgradeTapped() {
        Analytics.track(.bookmarksUpgradeButtonTapped, source: bookmarksSource)
        upgradeTapped(with: product(for: feature.tier))
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        feature.presentUpgradeController(from: parentController, source: "bookmarks_locked")
    }

    private func product(for tier: SubscriptionTier) -> PlusProductPricingInfo? {
        products.first(where: { $0.identifier.subscriptionTier == tier })
    }
}
