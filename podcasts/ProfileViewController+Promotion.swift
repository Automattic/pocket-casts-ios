import MaterialComponents.MaterialBottomSheet

extension ProfileViewController: PromotionRedeemedDelegate {
    func showPromotionViewController(promoCode: String?) {
        let promoVC = PromotionViewController()
        promoVC.promoCode = promoCode
        promoVC.delegate = self
        present(SJUIUtils.popupNavController(for: promoVC), animated: true, completion: nil)
    }

    func showPromotionRedeemedAcknowledgement() {
        let promoAcknowledgementVC = PromotionAcknowledgementViewController(serverMessage: promoRedeemedMessage)
        let bottomSheet = MDCBottomSheetController(contentViewController: promoAcknowledgementVC)
        let shapeGenerator = MDCCurvedRectShapeGenerator(cornerSize: CGSize(width: 8, height: 8))
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        present(bottomSheet, animated: true, completion: nil)
    }

    func promotionRedeemed(message: String) {
        promoRedeemedMessage = message
    }
}
