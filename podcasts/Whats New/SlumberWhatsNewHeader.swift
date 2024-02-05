import SwiftUI
import SafariServices
import PocketCastsServer

struct SlumberWhatsNewHeader: View {
    var body: some View {
        HStack {
            Group {
                PodcastCover(podcastUuid: "82e37e80-755d-0138-eddc-0acc26574db2")
                PodcastCover(podcastUuid: "9478cc80-7c42-0138-edfe-0acc26574db2")
                PodcastCover(podcastUuid: "37082d70-e945-0137-b6eb-0acc26574db2")
                PodcastCover(podcastUuid: "62200ab0-b7ec-0139-f606-0acc26574db2")

            }
                .frame(width: 120, height: 120)
        }
            .environment(\.renderForSharing, false)
    }
}

class SlumberAnnouncementViewModel {
    private lazy var upgradeOrRedeemViewModel = SlumberUpgradeRedeemViewModel()

    var buttonTitle: String {
        SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberRedeem : L10n.plusSubscribeTo
    }

    var message: String {
        (SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberPlusDescription("**\(Settings.slumberPromoCode ?? "")**") : L10n.announcementSlumberNonPlusDescription).replacingOccurrences(of: L10n.announcementSlumberPlusDescriptionLearnMore, with: "[\(L10n.announcementSlumberPlusDescriptionLearnMore)](https://slumberstudios.com)")
    }

    func showRedeemOrUpgrade() {
        upgradeOrRedeemViewModel.showRedeemOrUpgrade()
    }
}

class SlumberUpgradeRedeemViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature = .slumber
    let upgradeSource: String = "slumber"

    var upgradeLabel: String {
        return L10n.plusSubscribeTo
    }

    func showRedeemOrUpgrade() {
        SubscriptionHelper.hasActiveSubscription() ? showRedeem() : upgradeTapped()
    }

    private func showRedeem() {
        guard let parentController = SceneHelper.rootViewController(), let url = URL(string: "https://slumberstudios.com/pocketcasts/") else { return }

        let safariController = SFSafariViewController(with: url)
        safariController.modalPresentationStyle = .formSheet
        parentController.present(safariController, animated: true)
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        feature.presentUpgradeController(from: parentController, source: upgradeSource)
    }
}

#Preview {
    SlumberWhatsNewHeader()
}
