import Foundation
import PocketCastsServer

/// Drives the highlighted transcripts What's New announcement.
///
/// Both Plus and Free users see the same headline and copy. Plus users get an
/// education moment that simply dismisses, while Free users see a Plus badge and
/// a "Start Free Trial" call to action that opens the upsell paywall.
class TranscriptAnnouncementViewModel {
    private var isSubscriber: Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

    /// Show the Plus badge to Free users only, framing the announcement as an upsell.
    var displayTier: SubscriptionTier {
        isSubscriber ? .none : .plus
    }

    var buttonTitle: String {
        isSubscriber ? L10n.gotIt : L10n.freeTrialStartButton
    }

    func buttonAction() {
        // Plus users just dismiss; Free users are taken to the upgrade paywall.
        SceneHelper.rootViewController()?.dismiss(animated: true) {
            guard !SubscriptionHelper.hasActiveSubscription(),
                  let rootViewController = SceneHelper.rootViewController() else {
                return
            }

            PaidFeature.syncedTranscripts.presentUpgradeController(from: rootViewController, source: .syncedTranscripts)
        }
    }
}
