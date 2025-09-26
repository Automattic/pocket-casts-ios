import PocketCastsServer
import SwiftUI

struct BookmarksLockedStateView<Style: EmptyStateViewStyle>: View {
    @EnvironmentObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: Style
    @StateObject private var upgradeModel: BookmarksUpgradeViewModel

    private var title: String = L10n.noBookmarksTitle
    private var message: String = L10n.noBookmarksLockedMessage
    private var actionTitle: String = L10n.noBookmarksLockedButtonTitle

    init(style: Style, feature: PaidFeature, source: BookmarkAnalyticsSource) {
        self.style = style
        _upgradeModel = .init(wrappedValue: .init(feature: feature, source: source))
    }

    var body: some View {
        EmptyStateView(title: title, message: message, icon: { Image("bookmarks-profile") }, actions: [
            .init(title: actionTitle, action: {
                upgradeModel.upgradeTapped()
            })
        ], style: style, maxContentWidth: .infinity)
    }
}

class BookmarksUpgradeViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature
    let bookmarksSource: BookmarkAnalyticsSource
    let upgradeSource: PlusUpgradeViewSource

    init(feature: PaidFeature, source: BookmarkAnalyticsSource, upgradeSource: PlusUpgradeViewSource = .bookmarksLocked) {
        self.feature = feature
        self.bookmarksSource = source
        self.upgradeSource = upgradeSource

        super.init()
    }

    var upgradeLabel: String {
        guard let offer = product(for: feature.tier)?.offer, offer.type == .freeTrial else {
            return L10n.upgradeToPlan(feature.tier == .patron ? L10n.patron : L10n.pocketCastsPlusShort)
        }

        return offer.title
    }

    func upgradeTapped() {
        Analytics.track(.bookmarksGetBookmarksButtonTapped, source: bookmarksSource)
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
