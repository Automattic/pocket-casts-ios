import Foundation

extension UIScrollView {
    func applyInsetForMiniPlayer(additionalBottomInset: CGFloat = 0) {
        let existingInset = contentInset
        contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: existingInset.bottom + Constants.Values.miniPlayerOffset + additionalBottomInset, right: existingInset.right)

        let existingScrollIndicatorInset = verticalScrollIndicatorInsets
        verticalScrollIndicatorInsets = UIEdgeInsets(top: existingScrollIndicatorInset.top, left: existingScrollIndicatorInset.left, bottom: existingScrollIndicatorInset.bottom + Constants.Values.miniPlayerOffset + additionalBottomInset, right: existingScrollIndicatorInset.right)
    }

    func updateContentInset(multiSelectEnabled: Bool) {
        let existingInset = contentInset
        let multiSelectFooterOffset: CGFloat = multiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: miniPlayerOffset + multiSelectFooterOffset, right: existingInset.right)

        let existingScrollIndicatorInset = verticalScrollIndicatorInsets
        verticalScrollIndicatorInsets = UIEdgeInsets(top: existingScrollIndicatorInset.top, left: existingScrollIndicatorInset.left, bottom: miniPlayerOffset + multiSelectFooterOffset, right: existingScrollIndicatorInset.right)
    }
}
