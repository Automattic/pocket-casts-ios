import Foundation
import PocketCastsServer
import PocketCastsUtils
import StoreKit

class ReferralsCoordinator {

    var referralsOfferInfo: ReferralsOfferInfo = ReferralsOfferInfoIAP()

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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
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
                                                   coordinator: self,
                                                   canClaimPass: self.isReferralAvailableToClaim,
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

    private func translateToProduct(offer: ReferralValidate) -> IAPProductID? {
        if offer.offer == "two_months_free" {
            return IAPProductID.yearlyReferral
        }
        return nil
    }

    func purchase(offer: ReferralValidate) -> Bool {
        guard let productID = translateToProduct(offer: offer) else {
            return false
        }

        let purchaseHandler = IAPHelper.shared
        guard purchaseHandler.canMakePurchases else {
            return false
        }

        let discount = makeIAPDiscount(offer: offer, discount: purchaseHandler.getPromoOffer(productID))

        guard purchaseHandler.buyProduct(identifier: productID, discount: discount) else {
            return false
        }

        return true
    }

    private func makeIAPDiscount(offer: ReferralValidate, discount: SKProductDiscount?) -> IAPDiscountInfo? {
        guard let discount, let identifier = discount.identifier else {
            return nil
        }
        return IAPDiscountInfo(identifier: identifier, uuid: UUID(), timestamp: Int(Date.now.timeIntervalSince1970), key: "", signature: "")
    }
}
