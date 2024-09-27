import Foundation
import PocketCastsServer
import PocketCastsUtils

class ReferralsCoordinator {

    var referralsOfferInfo: ReferralsOfferInfo = ReferralsOfferInfoMock()

    var areReferralsAvailableToSend: Bool {
        return FeatureFlag.referrals.enabled && SubscriptionHelper.hasActiveSubscription()
    }

    var isReferralAvailableToClaim: Bool {
        return FeatureFlag.referrals.enabled && !SubscriptionHelper.hasActiveSubscription() && Settings.referralURL != nil
    }

    static var shared: ReferralsCoordinator = {
        ReferralsCoordinator()
    }()

    func startClaimFlow(from viewController: UIViewController) {
        var referralURL: URL?
        if let storedReferralURL = Settings.referralURL {
            referralURL = URL(string: storedReferralURL)
        }
        startClaimFlow(from: viewController, referralURL: referralURL)
    }

    func startClaimFlow(from viewController: UIViewController, referralURL: URL? = nil, onComplete: (() -> ())? = nil) {
        Task {
            await MainActor.run {
                var url: URL?
                if let referralURL {
                    Settings.referralURL = referralURL.absoluteString
                    url = referralURL
                } else {
                    if let urlString = Settings.referralURL {
                        url = URL(string: urlString)
                    }
                }

                let viewModel = ReferralClaimPassModel(referralURL: url,
                                                       offerInfo: referralsOfferInfo,
                                                       canClaimPass: isReferralAvailableToClaim,
                                                       onComplete: {
                    viewController.dismiss(animated: true)
                    onComplete?()
                },
                                                       onCloseTap: {
                    viewController.dismiss(animated: true)
                    onComplete?()
                })
                let referralClaimPassVC = ReferralClaimPassVC(viewModel: viewModel)
                viewController.present(referralClaimPassVC, animated: true)
            }
        }
    }
}
