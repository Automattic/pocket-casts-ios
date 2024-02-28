import UIKit

extension ProfileViewController: PromotionRedeemedDelegate {
    func showPromotionViewController(promoCode: String?) {
        let promoVC = PromotionViewController()
        promoVC.promoCode = promoCode
        promoVC.delegate = self
        present(SJUIUtils.popupNavController(for: promoVC), animated: true, completion: nil)
    }

    func showPromotionRedeemedAcknowledgement() {
        let promoAcknowledgementVC = PromotionAcknowledgementViewController(serverMessage: promoRedeemedMessage)

        if let bottomSheet = promoAcknowledgementVC.sheetPresentationController {
            bottomSheet.detents = [.medium()]
            bottomSheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            // The Promo Acknowledgement VC implements its own grabber UI.
            bottomSheet.prefersGrabberVisible = false
        }

        present(promoAcknowledgementVC, animated: true, completion: nil)
    }

    func promotionRedeemed(message: String) {
        promoRedeemedMessage = message
    }
}
