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
        let feature = upgradeModel.feature

        let tierName: String
        var secondaryTierName: String? = nil

        switch feature.tier {
        case .patron:
            tierName = L10n.patron
            secondaryTierName = feature.inEarlyAccess ? L10n.pocketCastsPlusShort : nil
        case .plus:
            tierName = L10n.pocketCastsPlusShort
        case .none:
            tierName = L10n.pocketCastsPlusShort
        }

        // Show the regular unlock message if there isn't a secondary early access tier to display
        guard let secondaryTierName else {
            return L10n.bookmarksLockedMessage(tierName).preventWidows()
        }

        return L10n.bookmarksEarlyAccessLockedMessage(tierName, secondaryTierName).preventWidows()
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

class BookmarksUpgradeViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature
    let bookmarksSource: BookmarkAnalyticsSource
    let upgradeSource: String

    init(feature: PaidFeature, source: BookmarkAnalyticsSource, upgradeSource: String = "bookmarks_locked") {
        self.feature = feature
        self.bookmarksSource = source
        self.upgradeSource = upgradeSource

        super.init()
    }

    var upgradeLabel: String {
        return L10n.plusSubscribeTo
    }

    func upgradeTapped() {
        Analytics.track(.bookmarksUpgradeButtonTapped, source: bookmarksSource)
        showUpgrade()
    }

    func showUpgrade() {
        upgradeTapped(with: product(for: feature.tier))
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        feature.presentUpgradeController(from: parentController, source: upgradeSource)
    }

    private func product(for tier: SubscriptionTier) -> PlusProductPricingInfo? {
        products.first(where: { $0.identifier.subscriptionTier == tier })
    }
}
