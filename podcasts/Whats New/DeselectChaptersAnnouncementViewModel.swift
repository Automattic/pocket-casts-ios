import Foundation
import PocketCastsServer
import PocketCastsUtils

class DeselectChaptersAnnouncementViewModel {
    var isPatronAnnouncementEnabled: Bool {
        PaidFeature.deselectChapters.isUnlocked
    }

    // Only for TestFlight early access
    var isPlusAnnouncementEnabled: Bool {
        PaidFeature.deselectChapters.tier == .plus
        && SubscriptionHelper.activeTier == .plus
    }

    var isPlusFreeAnnouncementEnabled: Bool {
        PaidFeature.deselectChapters.tier == .plus
        && SubscriptionHelper.activeTier < .patron
        && BuildEnvironment.current == .appStore
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
                PaidFeature.deselectChapters.presentUpgradeController(from: rootViewController, source: .deselectChapterWhatsNew)
            }
        }
    }
}
