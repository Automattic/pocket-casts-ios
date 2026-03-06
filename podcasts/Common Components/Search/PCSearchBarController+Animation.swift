import Foundation

extension PCSearchBarController {
    func showCancelButton() {
        if !shouldShowCancelButton || cancelButtonShowing { return }

        cancelButtonShowing = true

        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) { [weak self] in
            guard let self = self else { return }

            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.roundedBgTrailingSpaceParent.isActive = false
                self.roundedBgTrailingSpaceToCancel.isActive = true
                self.view.layoutIfNeeded()
            }) { _ in
                UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: {
                    self.cancelButton.alpha = 1
                })
            }
        }
    }

    func hideCancelButton() {
        if !shouldShowCancelButton || !cancelButtonShowing { return }

        cancelButtonShowing = false

        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime / 2, animations: {
            self.cancelButton.alpha = 0
        }) { _ in
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.roundedBgTrailingSpaceToCancel.isActive = false
                self.roundedBgTrailingSpaceParent.isActive = true
                self.view.layoutIfNeeded()
            })
        }
    }
}
