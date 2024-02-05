import SwiftUI

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

class SlumberUpgradeViewModel: PlusAccountPromptViewModel {
    let feature: PaidFeature = .slumber
    let upgradeSource: String = "slumber"

    var upgradeLabel: String {
        return L10n.plusSubscribeTo
    }

    func showUpgrade() {
        upgradeTapped()
    }

    override func showModal(for product: PlusPricingInfoModel.PlusProductPricingInfo? = nil) {
        guard let parentController = SceneHelper.rootViewController() else { return }

        feature.presentUpgradeController(from: parentController, source: upgradeSource)
    }
}

#Preview {
    SlumberWhatsNewHeader()
}
