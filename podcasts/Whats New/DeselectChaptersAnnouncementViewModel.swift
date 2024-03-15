import Foundation
import PocketCastsServer
import PocketCastsUtils

class DeselectChaptersAnnouncementViewModel {
    var isPatronAnnouncementEnabled: Bool {
        FeatureFlag.deselectChapters.enabled
            && PaidFeature.deselectChapters.tier == .patron
            && SubscriptionHelper.activeTier == .patron
    }

    // Only for TestFlight early access
    var isPlusAnnouncementEnabled: Bool {
        FeatureFlag.deselectChapters.enabled
            && PaidFeature.deselectChapters.tier == .plus
            && SubscriptionHelper.activeTier == .plus
    }

    var isPlusFreeAnnouncementEnabled: Bool {
        FeatureFlag.deselectChapters.enabled
            && PaidFeature.deselectChapters.tier == .plus
            && SubscriptionHelper.activeTier < .patron
    }

    var plusFreeMessage: String {
        SubscriptionHelper.hasActiveSubscription() ? L10n.announcementDeselectChaptersPlus : L10n.announcementDeselectChaptersFree
    }

    var plusFreeButtonTitle: String {
        SubscriptionHelper.hasActiveSubscription() ? L10n.gotIt : L10n.upgradeToPlus
    }

    func buttonAction() {
        // If Plus, just dismiss What's New
        // If free user, show upgrade
        SceneHelper.rootViewController()?.dismiss(animated: true) {
            if !SubscriptionHelper.hasActiveSubscription(), let rootViewController = SceneHelper.rootViewController() {
                PaidFeature.deselectChapters.presentUpgradeController(from: rootViewController, source: "deselect_chapters_whats_new")
            }
        }
    }
}
